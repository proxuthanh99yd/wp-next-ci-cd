#!/bin/bash

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

echo "✅ WordPress setup completed" 