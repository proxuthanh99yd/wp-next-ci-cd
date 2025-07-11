#!/bin/bash

# Load environment variables if .env exists
if [ -f ".env" ]; then
    # Use source command to load .env file safely
    set -a  # automatically export all variables
    source .env 2>/dev/null || true
    set +a  # turn off automatic export
fi

# Default values if not set in .env
REPO_URL="${REPO_URL:-git@github.com:yourname/yourrepo.git}"
PROJECT_DIR="${PROJECT_DIR:-/home/${PROJECT_NAME:-wp-next-ci-cd}}"
DOMAIN_NEXT="${NEXTJS_DOMAINS:-domain1.com domain2.com domain3.com}"
CMS_DOMAIN="${CMS_DOMAIN:-cms.domain1.com}"
EMAIL="${SSL_EMAIL:-your@email.com}"

# Update system and install dependencies
sudo apt update
sudo apt install -y docker.io docker-compose git

# Clone repository
cd /home
if [ ! -d "$PROJECT_DIR" ]; then
    git clone $REPO_URL $PROJECT_DIR
fi

# Create .env file for WordPress if not exists
cd $PROJECT_DIR
if [ ! -f ".env" ]; then
    echo "Creating .env file from template..."
    cp env.example .env
    
    # Auto-generate default values if not provided
    if [ -z "$PRIMARY_DOMAIN" ]; then
        PRIMARY_DOMAIN="example.com"
        echo "PRIMARY_DOMAIN=$PRIMARY_DOMAIN" >> .env
    fi
    
    if [ -z "$CMS_DOMAIN" ]; then
        CMS_DOMAIN="cms.$PRIMARY_DOMAIN"
        echo "CMS_DOMAIN=$CMS_DOMAIN" >> .env
    fi
    
    if [ -z "$SSL_EMAIL" ]; then
        SSL_EMAIL="admin@$PRIMARY_DOMAIN"
        echo "SSL_EMAIL=$SSL_EMAIL" >> .env
    fi
    
    # Set default backup URL
    if [ -z "$WORDPRESS_BACKUP_URL" ]; then
        WORDPRESS_BACKUP_URL="https://example.com/backup.wpress"
        echo "WORDPRESS_BACKUP_URL=$WORDPRESS_BACKUP_URL" >> .env
    fi
    
    # Generate random passwords for database
    MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
    MYSQL_PASSWORD=$(openssl rand -base64 32)
    WORDPRESS_DB_PASSWORD=$(openssl rand -base64 32)
    
    echo "MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD" >> .env
    echo "MYSQL_PASSWORD=$MYSQL_PASSWORD" >> .env
    echo "WORDPRESS_DB_PASSWORD=$WORDPRESS_DB_PASSWORD" >> .env
    
    echo "✅ Auto-generated .env file with default values"
    echo "⚠️  Please update PRIMARY_DOMAIN, CMS_DOMAIN, and SSL_EMAIL in .env file for production use"
fi

# Load environment variables from .env
# Use source command to load .env file safely
set -a  # automatically export all variables
source .env 2>/dev/null || true
set +a  # turn off automatic export

# Clone NextJS repo nếu có cấu hình và chưa tồn tại thư mục nextjs-app
if [ ! -d "nextjs-app" ] && [ ! -z "$NEXTJS_REPO" ]; then
    echo "🚀 Cloning NextJS repo: $NEXTJS_REPO"
    if git clone "$NEXTJS_REPO" nextjs-app; then
        echo "✅ NextJS repo cloned successfully"
    else
        echo "❌ Failed to clone NextJS repo: $NEXTJS_REPO"
        echo "   Please check the repository URL and your git access"
        exit 1
    fi
elif [ -d "nextjs-app" ] && [ -z "$NEXTJS_REPO" ]; then
    echo "⚠️  nextjs-app directory exists but NEXTJS_REPO not configured in .env"
    echo "   Please set NEXTJS_REPO in .env file or remove nextjs-app directory"
elif [ -d "nextjs-app" ] && [ ! -z "$NEXTJS_REPO" ]; then
    echo "ℹ️  nextjs-app directory already exists, skipping clone"
    echo "   To force re-clone, remove the nextjs-app directory first"
fi

# Set fallback values if still empty
PRIMARY_DOMAIN="${PRIMARY_DOMAIN:-example.com}"
CMS_DOMAIN="${CMS_DOMAIN:-cms.example.com}"
SSL_EMAIL="${SSL_EMAIL:-admin@example.com}"

# Set proper file permissions
chmod 600 .env

# Generate nginx config from environment variables
chmod +x generate-nginx-config.sh
chmod +x validate-config.sh

# Validate configuration before proceeding
./validate-config.sh
if [ $? -ne 0 ]; then
    echo "❌ Configuration validation failed!"
    exit 1
fi

./generate-nginx-config.sh

# Install certbot if not available
if ! command -v certbot &> /dev/null; then
    echo "📦 Installing certbot..."
    sudo apt install -y certbot
fi

# Generate SSL certificate for primary domain (covers all subdomains)
echo "🔒 Generating SSL certificates..."
if sudo certbot certonly --standalone --non-interactive --agree-tos -m $SSL_EMAIL -d $PRIMARY_DOMAIN -d $CMS_DOMAIN; then
    echo "✅ SSL certificates generated successfully!"
else
    echo "⚠️  SSL certificate generation failed (this is normal for local development)"
    echo "   Certificates will be generated when domains are properly configured"
fi

# Verify SSL certificates exist (optional for development)
if [ -f "/etc/letsencrypt/live/$PRIMARY_DOMAIN/fullchain.pem" ]; then
    echo "✅ SSL certificate for $PRIMARY_DOMAIN found"
else
    echo "⚠️  SSL certificate for $PRIMARY_DOMAIN not found (normal for development)"
fi

if [ -f "/etc/letsencrypt/live/$CMS_DOMAIN/fullchain.pem" ]; then
    echo "✅ SSL certificate for $CMS_DOMAIN found"
else
    echo "⚠️  SSL certificate for $CMS_DOMAIN not found (normal for development)"
fi

# Start WordPress and database first
echo -e "\n🚀 Starting WordPress and database..."
docker-compose up -d db wordpress

# Fix WordPress permissions
echo -e "\n🔧 Fixing WordPress permissions..."
docker exec wordpress chown -R www-data:www-data /var/www/html
docker exec wordpress chmod -R 755 /var/www/html
docker exec wordpress chmod -R 777 /var/www/html/wp-content

# Wait for database to be ready
echo -e "\n⏳ Waiting for database to be ready..."
sleep 20

# Install WP-CLI first
echo -e "\n📦 Installing WP-CLI..."
docker exec wordpress curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
docker exec wordpress chmod +x wp-cli.phar
docker exec wordpress mv wp-cli.phar /usr/local/bin/wp
echo "✅ WP-CLI installed successfully"

# Wait for WordPress to be fully ready
echo -e "\n⏳ Waiting for WordPress to be ready..."
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    if docker exec wordpress wp core is-installed --allow-root 2>/dev/null; then
        echo -e "\n✅ WordPress is ready!"
        break
    fi
    
    echo -e "\n⏳ Attempt $attempt/$max_attempts: WordPress not ready yet..."
    
    # Try to install WordPress if not installed
    if [ $attempt -eq 5 ]; then
        echo -e "\n🔧 Attempting to install WordPress..."
        if docker exec wordpress wp core install --url=http://localhost --title="My WordPress Site" --admin_user=admin --admin_password=admin123 --admin_email=admin@localhost.com --allow-root 2>/dev/null; then
            echo -e "\n✅ WordPress installed successfully!"
            break
        else
            echo -e "\n⚠️  WordPress installation failed, continuing to wait..."
        fi
    fi
    
    sleep 10
    ((attempt++))
    
    if [ $attempt -gt $max_attempts ]; then
        echo -e "\n❌ WordPress failed to start properly!"
        echo "Check logs with: docker logs wordpress"
        exit 1
    fi
done

# Install WordPress plugins in specific order
echo -e "\n🔧 Installing WordPress plugins..."

# Install plugins from wp-plugin folder in specific order
if [ -d "wp-plugin" ]; then
    # Define plugin installation order
    declare -a plugins=(
        "all-in-one-wp-migration"
        "all-in-one-wp-migration-unlimited-extension"
    )
    
    for plugin_name in "${plugins[@]}"; do
        plugin_file="wp-plugin/${plugin_name}.zip"
        if [ -f "$plugin_file" ]; then
            echo -e "\n📦 Installing $plugin_name..."
            
            # Copy plugin to WordPress container
            docker cp "$plugin_file" wordpress:/tmp/
            
            # Install plugin using WP-CLI
            if docker exec wordpress wp plugin install /tmp/"$(basename "$plugin_file")" --activate --allow-root; then
                echo "✅ $plugin_name installed and activated successfully"
                
                # Wait a moment for plugin to fully activate
                sleep 5
            else
                echo "❌ Failed to install $plugin_name"
            fi
            
            # Clean up temporary file
            docker exec wordpress rm -f /tmp/"$(basename "$plugin_file")"
        else
            echo "⚠️  Plugin file not found: $plugin_file"
        fi
    done
    
    # Install any other plugins that might be in the folder
    for plugin_file in wp-plugin/*.zip; do
        if [ -f "$plugin_file" ]; then
            plugin_name=$(basename "$plugin_file" .zip)
            
            # Skip if already installed in order
            if [[ " ${plugins[@]} " =~ " ${plugin_name} " ]]; then
                continue
            fi
            
            echo -e "\n📦 Installing additional plugin: $plugin_name..."
            
            # Copy plugin to WordPress container
            docker cp "$plugin_file" wordpress:/tmp/
            
            # Install plugin using WP-CLI
            if docker exec wordpress wp plugin install /tmp/"$(basename "$plugin_file")" --activate --allow-root; then
                echo "✅ $plugin_name installed and activated successfully"
            else
                echo "❌ Failed to install $plugin_name"
            fi
            
            # Clean up temporary file
            docker exec wordpress rm -f /tmp/"$(basename "$plugin_file")"
        fi
    done
else
    echo "⚠️  wp-plugin folder not found"
fi

# Function to find backup file in local directory
find_local_backup() {
    # Check wp-content/ai1wm-backups first (WordPress backup directory)
    local backup_dir="wp-content/ai1wm-backups"
    if [ -d "$backup_dir" ]; then
        # Find the most recent .wpress file
        local latest_backup=$(find "$backup_dir" -name "*.wpress" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
        if [ ! -z "$latest_backup" ]; then
            echo "$latest_backup"
            return 0
        fi
    fi
    
    # Fallback to wp-backups directory
    local backup_dir="wp-backups"
    if [ -d "$backup_dir" ]; then
        # Find the most recent .wpress file
        local latest_backup=$(find "$backup_dir" -name "*.wpress" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
        if [ ! -z "$latest_backup" ]; then
            echo "$latest_backup"
            return 0
        fi
    fi
    return 1
}

# Download and restore WordPress backup if URL is provided
if [ ! -z "$WORDPRESS_BACKUP_URL" ] && [ "$WORDPRESS_BACKUP_URL" != "https://example.com/backup.wpress" ]; then
    echo -e "\n📥 Downloading WordPress backup..."
    
    # Create ai1wm-backups directory if it doesn't exist
    docker exec wordpress mkdir -p /var/www/html/wp-content/ai1wm-backups
    
    # Fix permissions for backup directory
    docker exec wordpress chown -R www-data:www-data /var/www/html/wp-content/ai1wm-backups
    docker exec wordpress chmod -R 777 /var/www/html/wp-content/ai1wm-backups
    
    # Get filename from URL (extract the last part of the path)
    backup_filename=$(basename "$WORDPRESS_BACKUP_URL")
    echo "📁 Backup filename: $backup_filename"
    
    # Check if backup file already exists in container
    if docker exec wordpress test -f "/var/www/html/wp-content/ai1wm-backups/$backup_filename"; then
        echo "✅ Backup file already exists: $backup_filename"
    else
                # Download backup file to WordPress container (using curl which is usually available)
        echo "📥 Downloading backup file..."
        if docker exec wordpress curl -L -o "/var/www/html/wp-content/ai1wm-backups/$backup_filename" "$WORDPRESS_BACKUP_URL"; then
            echo "✅ Backup downloaded successfully: $backup_filename"
        else
            echo "❌ Failed to download backup from: $WORDPRESS_BACKUP_URL"
            exit 1
        fi
    fi
    
    # Wait a moment for file to be fully written
    sleep 3
    
    # Verify backup file exists and has content
    if docker exec wordpress test -s "/var/www/html/wp-content/ai1wm-backups/$backup_filename"; then
        echo "✅ Backup file verified: $backup_filename (size > 0)"
    else
        echo "❌ Backup file is empty or not found: $backup_filename"
        exit 1
    fi
    
    # Restore backup using WP-CLI
    echo -e "\n🔄 Restoring WordPress backup..."
                    if echo "y" | docker exec wordpress wp ai1wm restore "/var/www/html/wp-content/ai1wm-backups/$backup_filename" --allow-root; then
                    echo "✅ WordPress backup restored successfully!"
                    
                    # Wait for restore to complete
                    sleep 10
                    
                    # Fix permissions after restore
                    echo "🔧 Fixing permissions after restore..."
                    docker exec wordpress chown -R www-data:www-data /var/www/html
                    docker exec wordpress chmod -R 755 /var/www/html
                    docker exec wordpress chmod -R 777 /var/www/html/wp-content
                    
                    # Verify WordPress is still functional after restore
                    if docker exec wordpress wp core is-installed --allow-root 2>/dev/null; then
                        echo "✅ WordPress verification after restore: OK"
                    else
                        echo "⚠️  WordPress verification after restore: Failed"
                    fi
    else
        echo "❌ Failed to restore WordPress backup"
        exit 1
    fi
else
    echo -e "\n⚠️  No backup URL provided or using default URL."
    
    # Try to find local backup file
    echo "🔍 Looking for local backup files..."
    local_backup=$(find_local_backup)
    
    if [ ! -z "$local_backup" ]; then
        echo "📁 Found local backup: $local_backup"
        
        # Create ai1wm-backups directory if it doesn't exist
        docker exec wordpress mkdir -p /var/www/html/wp-content/ai1wm-backups
        
        # Fix permissions for backup directory
        docker exec wordpress chown -R www-data:www-data /var/www/html/wp-content/ai1wm-backups
        docker exec wordpress chmod -R 777 /var/www/html/wp-content/ai1wm-backups
        
        # Get filename from path
        backup_filename=$(basename "$local_backup")
        echo "📁 Backup filename: $backup_filename"
        
        # Copy local backup to container
        echo "📥 Copying local backup to container..."
        if docker cp "$local_backup" wordpress:/var/www/html/wp-content/ai1wm-backups/; then
            echo "✅ Local backup copied successfully: $backup_filename"
            
            # Wait a moment for file to be fully written
            sleep 3
            
            # Verify backup file exists and has content
            if docker exec wordpress test -s "/var/www/html/wp-content/ai1wm-backups/$backup_filename"; then
                echo "✅ Backup file verified: $backup_filename (size > 0)"
                
                # Restore backup using WP-CLI
                echo -e "\n🔄 Restoring WordPress backup..."
                if echo "y" | docker exec wordpress wp ai1wm restore "/var/www/html/wp-content/ai1wm-backups/$backup_filename" --allow-root; then
                    echo "✅ WordPress backup restored successfully!"
                    
                    # Wait for restore to complete
                    sleep 10
                    
                    # Fix permissions after restore
                    echo "🔧 Fixing permissions after restore..."
                    docker exec wordpress chown -R www-data:www-data /var/www/html
                    docker exec wordpress chmod -R 755 /var/www/html
                    docker exec wordpress chmod -R 777 /var/www/html/wp-content
                    
                    # Verify WordPress is still functional after restore
                    if docker exec wordpress wp core is-installed --allow-root 2>/dev/null; then
                        echo "✅ WordPress verification after restore: OK"
                    else
                        echo "⚠️  WordPress verification after restore: Failed"
                    fi
                else
                    echo "❌ Failed to restore WordPress backup"
                    exit 1
                fi
            else
                echo "❌ Backup file is empty or not found: $backup_filename"
                exit 1
            fi
        else
            echo "❌ Failed to copy local backup to container"
            exit 1
        fi
    else
        echo "   To restore backup, either:"
        echo "   1. Set WORDPRESS_BACKUP_URL in .env file, or"
        echo "   2. Place .wpress backup file in wp-content/ai1wm-backups/ directory"
    fi
fi

# Verify WordPress is fully functional after plugin installation
echo -e "\n🔍 Verifying WordPress functionality..."
if ! docker exec wordpress wp core is-installed --allow-root 2>/dev/null; then
    echo -e "\n❌ WordPress verification failed after plugin installation!"
    exit 1
fi

echo -e "\n✅ WordPress is fully ready with plugins installed!"

# Start nginx first (will serve static content and proxy to NextJS later)
echo -e "\n🚀 Starting nginx..."
# Start nginx without building other services
docker-compose up -d --no-deps nginx

# Now build and start NextJS
echo -e "\n🚀 Building and starting NextJS..."
docker-compose build nextjs
docker-compose up -d nextjs

# Wait for NextJS to be ready
echo -e "\n⏳ Waiting for NextJS to be ready..."
sleep 20

# Enable NextJS nginx config after NextJS is ready
echo -e "\n🔄 Enabling NextJS nginx configuration..."
# Uncomment NextJS HTTP server block
sed -i 's/# server {/server {/g' nginx/default.conf
sed -i 's/#     listen 80;/    listen 80;/g' nginx/default.conf
sed -i 's/#     server_name sanpham.ziohair.vn booking.ziohair.vn localhost;/    server_name sanpham.ziohair.vn booking.ziohair.vn localhost;/g' nginx/default.conf
sed -i 's/#     # Security headers/    # Security headers/g' nginx/default.conf
sed -i 's/#     add_header/    add_header/g' nginx/default.conf
sed -i 's/#     location \/ {/    location \/ {/g' nginx/default.conf
sed -i 's/#         proxy_pass/        proxy_pass/g' nginx/default.conf
sed -i 's/#         proxy_http_version/        proxy_http_version/g' nginx/default.conf
sed -i 's/#         proxy_set_header/        proxy_set_header/g' nginx/default.conf
sed -i 's/#         proxy_cache_bypass/        proxy_cache_bypass/g' nginx/default.conf
sed -i 's/#         # Timeout settings/        # Timeout settings/g' nginx/default.conf
sed -i 's/#         proxy_connect_timeout/        proxy_connect_timeout/g' nginx/default.conf
sed -i 's/#         proxy_send_timeout/        proxy_send_timeout/g' nginx/default.conf
sed -i 's/#         proxy_read_timeout/        proxy_read_timeout/g' nginx/default.conf
sed -i 's/#     }/    }/g' nginx/default.conf
sed -i 's/# }/}/g' nginx/default.conf

# Reload nginx configuration
docker exec nginx nginx -s reload

# Final verification
echo -e "\n🔍 Final verification..."
sleep 10

# Check all services
echo -e "\n📋 Service Status:"
if docker ps | grep -q "mysql"; then
    echo "  ✅ Database (MySQL) - Running"
else
    echo "  ❌ Database (MySQL) - Not running"
fi

if docker ps | grep -q "wordpress"; then
    echo "  ✅ WordPress - Running"
else
    echo "  ❌ WordPress - Not running"
fi

if docker ps | grep -q "nginx"; then
    echo "  ✅ Nginx - Running"
else
    echo "  ❌ Nginx - Not running"
fi

if docker ps | grep -q "nextjs"; then
    echo "  ✅ NextJS - Running"
else
    echo "  ❌ NextJS - Not running"
fi

echo -e "\n🎉 Setup completed successfully!"
echo -e "\n📋 Access Information:"
echo "  WordPress Admin: http://localhost/wp-admin"
echo "  NextJS App: http://localhost:3000"
echo "  Nginx: http://localhost"
echo -e "\n📝 Next Steps:"
echo "  1. Update PRIMARY_DOMAIN, CMS_DOMAIN, and SSL_EMAIL in .env for production"
echo "  2. Configure your domain DNS settings"
echo "  3. Run SSL certificate generation again with proper domains"
echo "  4. Customize your WordPress site and NextJS app"
