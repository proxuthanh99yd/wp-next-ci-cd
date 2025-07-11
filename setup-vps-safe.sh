#!/bin/bash

# Load environment variables if .env exists
if [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Default values if not set in .env
REPO_URL="${REPO_URL:-git@github.com:yourname/yourrepo.git}"
PROJECT_DIR="${PROJECT_DIR:-/home/${SSH_USER:-ubuntu}/${PROJECT_NAME:-your-project}}"
DOMAIN_NEXT="${NEXTJS_DOMAINS:-domain1.com domain2.com domain3.com}"
CMS_DOMAIN="${CMS_DOMAIN:-cms.domain1.com}"
EMAIL="${SSL_EMAIL:-your@email.com}"

echo "🔧 Starting safe VPS setup..."

# Function to check if setup is already running
check_setup_running() {
    if [ -f "/tmp/setup-vps.lock" ]; then
        echo "❌ Setup is already running or was interrupted!"
        echo "   If you're sure it's not running, remove: rm /tmp/setup-vps.lock"
        exit 1
    fi
}

# Function to create lock file
create_lock() {
    echo "Creating setup lock..."
    echo "PID: $$" > /tmp/setup-vps.lock
    echo "Started: $(date)" >> /tmp/setup-vps.lock
}

# Function to cleanup lock
cleanup_lock() {
    rm -f /tmp/setup-vps.lock
}

# Function to backup existing setup
backup_existing() {
    if [ -d "$PROJECT_DIR" ]; then
        echo "📦 Backup existing setup..."
        BACKUP_DIR="/home/ubuntu/backup-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$BACKUP_DIR"
        
        # Backup .env if exists
        if [ -f "$PROJECT_DIR/.env" ]; then
            cp "$PROJECT_DIR/.env" "$BACKUP_DIR/"
        fi
        
        # Backup nginx config
        if [ -f "$PROJECT_DIR/nginx/default.conf" ]; then
            cp -r "$PROJECT_DIR/nginx" "$BACKUP_DIR/"
        fi
        
        # Backup WordPress files
        if [ -d "$PROJECT_DIR/wp" ]; then
            cp -r "$PROJECT_DIR/wp" "$BACKUP_DIR/"
        fi
        
        echo "✅ Backup created at: $BACKUP_DIR"
    fi
}

# Function to stop existing containers
stop_existing_containers() {
    if [ -d "$PROJECT_DIR" ] && [ -f "$PROJECT_DIR/docker-compose.yml" ]; then
        echo "🛑 Stopping existing containers..."
        cd "$PROJECT_DIR"
        docker-compose down --remove-orphans 2>/dev/null || true
    fi
}

# Function to check and install dependencies
install_dependencies() {
    echo "📦 Installing dependencies..."
    
    # Update system
    sudo apt update
    
    # Install Docker if not exists
    if ! command -v docker &> /dev/null; then
        echo "Installing Docker..."
        sudo apt install -y docker.io
        sudo systemctl enable docker
        sudo usermod -aG docker $USER
    fi
    
    # Install Docker Compose if not exists
    if ! command -v docker-compose &> /dev/null; then
        echo "Installing Docker Compose..."
        sudo apt install -y docker-compose
    fi
    
    # Install Git if not exists
    if ! command -v git &> /dev/null; then
        echo "Installing Git..."
        sudo apt install -y git
    fi
    
    # Install Certbot if not exists
    if ! command -v certbot &> /dev/null; then
        echo "Installing Certbot..."
        sudo apt install -y certbot
    fi
}

# Function to setup repository
setup_repository() {
    echo "📥 Setting up repository..."
    
    # Remove existing directory if exists
    if [ -d "$PROJECT_DIR" ]; then
        echo "Removing existing project directory..."
        rm -rf "$PROJECT_DIR"
    fi
    
    # Clone repository
    cd /home/ubuntu
    if ! git clone "$REPO_URL" "$PROJECT_DIR"; then
        echo "❌ Failed to clone repository!"
        exit 1
    fi
    
    cd "$PROJECT_DIR"
}

# Function to setup environment
setup_environment() {
    echo "⚙️ Setting up environment..."
    
    # Create .env file if not exists
    if [ ! -f ".env" ]; then
        echo "Creating .env file from template..."
        cp env.example .env
        echo "⚠️  Please edit .env file with your actual values!"
        echo "Press Enter when ready to continue..."
        read
    fi
    
    # Load environment variables
    export $(cat .env | grep -v '^#' | xargs)
    
    # Validate environment variables
    if [ -z "$PRIMARY_DOMAIN" ] || [ -z "$CMS_DOMAIN" ] || [ -z "$SSL_EMAIL" ]; then
        echo "❌ Missing required environment variables!"
        echo "Please check PRIMARY_DOMAIN, CMS_DOMAIN, and SSL_EMAIL in .env file"
        exit 1
    fi
    
    # Set proper file permissions
    chmod 600 .env
}

# Function to setup SSL certificates
setup_ssl() {
    echo "🔒 Setting up SSL certificates..."
    
    # Check if certificates already exist
    if [ -f "/etc/letsencrypt/live/$PRIMARY_DOMAIN/fullchain.pem" ] && \
       [ -f "/etc/letsencrypt/live/$CMS_DOMAIN/fullchain.pem" ]; then
        echo "✅ SSL certificates already exist"
        return 0
    fi
    
    # Stop nginx if running to free port 80
    sudo systemctl stop nginx 2>/dev/null || true
    
    # Generate SSL certificates
    echo "Generating SSL certificates..."
    if ! sudo certbot certonly --standalone --non-interactive --agree-tos -m "$EMAIL" -d "$PRIMARY_DOMAIN" -d "$CMS_DOMAIN"; then
        echo "❌ Failed to generate SSL certificates!"
        echo "   Make sure domains point to this server and port 80 is free"
        exit 1
    fi
    
    # Verify SSL certificates
    if [ ! -f "/etc/letsencrypt/live/$PRIMARY_DOMAIN/fullchain.pem" ]; then
        echo "❌ SSL certificate for $PRIMARY_DOMAIN not found!"
        exit 1
    fi
    
    if [ ! -f "/etc/letsencrypt/live/$CMS_DOMAIN/fullchain.pem" ]; then
        echo "❌ SSL certificate for $CMS_DOMAIN not found!"
        exit 1
    fi
    
    echo "✅ SSL certificates generated successfully!"
}

# Function to setup nginx
setup_nginx() {
    echo "🌐 Setting up Nginx..."
    
    # Make scripts executable
    chmod +x generate-nginx-config.sh
    chmod +x validate-config.sh
    
    # Validate configuration
    ./validate-config.sh
    if [ $? -ne 0 ]; then
        echo "❌ Configuration validation failed!"
        exit 1
    fi
    
    # Generate nginx config
    ./generate-nginx-config.sh
}

# Function to start containers
start_containers() {
    echo "🐳 Starting containers..."
    
    # Build and start containers
    if ! docker-compose build; then
        echo "❌ Failed to build containers!"
        exit 1
    fi
    
    if ! docker-compose up -d; then
        echo "❌ Failed to start containers!"
        exit 1
    fi
    
    # Wait for containers to be healthy
    echo "⏳ Waiting for containers to be ready..."
    sleep 30
    
    # Check container status
    if ! docker-compose ps | grep -q "Up"; then
        echo "❌ Some containers failed to start!"
        docker-compose logs
        exit 1
    fi
    
    echo "✅ All containers started successfully!"
}

# Function to show status
show_status() {
    echo ""
    echo "🎉 Setup completed successfully!"
    echo ""
    echo "📋 Status:"
    docker-compose ps
    echo ""
    echo "🌐 Access URLs:"
    echo "   CMS: https://$CMS_DOMAIN"
    echo "   Next.js: https://$PRIMARY_DOMAIN"
    echo ""
    echo "📁 Project directory: $PROJECT_DIR"
    echo "📦 Backup directory: /home/ubuntu/backup-*"
}

# Main execution
main() {
    # Set error handling
    set -e
    
    # Check if setup is already running
    check_setup_running
    
    # Create lock file
    create_lock
    
    # Setup trap to cleanup on exit
    trap cleanup_lock EXIT
    
    # Execute setup steps
    backup_existing
    stop_existing_containers
    install_dependencies
    setup_repository
    setup_environment
    setup_ssl
    setup_nginx
    start_containers
    show_status
}

# Run main function
main "$@" 