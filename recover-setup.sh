#!/bin/bash

# Load environment variables if .env exists
if [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

PROJECT_DIR="${PROJECT_DIR:-/home/${PROJECT_NAME:-wp-next-ci-cd}}"

echo "🔧 Setup Recovery Tool"
echo "======================"

# Function to check what's broken
diagnose_issues() {
    echo "🔍 Diagnosing issues..."
    
    # Check if lock file exists
    if [ -f "/tmp/setup-vps.lock" ]; then
        echo "⚠️  Found setup lock file - setup may have been interrupted"
        cat /tmp/setup-vps.lock
    fi
    
    # Check if project directory exists
    if [ ! -d "$PROJECT_DIR" ]; then
        echo "❌ Project directory not found: $PROJECT_DIR"
        return 1
    fi
    
    # Check if docker-compose.yml exists
    if [ ! -f "$PROJECT_DIR/docker-compose.yml" ]; then
        echo "❌ docker-compose.yml not found"
        return 1
    fi
    
    # Check container status
    cd "$PROJECT_DIR"
    echo "📋 Container status:"
    docker-compose ps
    
    # Check SSL certificates
    if [ -z "$PRIMARY_DOMAIN" ] || [ -z "$CMS_DOMAIN" ]; then
        echo "⚠️  Cannot check SSL certificates - environment variables not loaded"
    else
        if [ ! -f "/etc/letsencrypt/live/$PRIMARY_DOMAIN/fullchain.pem" ]; then
            echo "❌ SSL certificate missing for $PRIMARY_DOMAIN"
        else
            echo "✅ SSL certificate exists for $PRIMARY_DOMAIN"
        fi
        
        if [ ! -f "/etc/letsencrypt/live/$CMS_DOMAIN/fullchain.pem" ]; then
            echo "❌ SSL certificate missing for $CMS_DOMAIN"
        else
            echo "✅ SSL certificate exists for $CMS_DOMAIN"
        fi
    fi
    
    # Check nginx config
    if [ ! -f "$PROJECT_DIR/nginx/default.conf" ]; then
        echo "❌ Nginx config not found"
    else
        echo "✅ Nginx config exists"
    fi
}

# Function to remove lock file
remove_lock() {
    echo "🔓 Removing setup lock file..."
    rm -f /tmp/setup-vps.lock
    echo "✅ Lock file removed"
}

# Function to restart containers
restart_containers() {
    echo "🔄 Restarting containers..."
    cd "$PROJECT_DIR"
    
    # Stop all containers
    docker-compose down
    
    # Start containers
    docker-compose up -d
    
    # Wait and check status
    sleep 10
    docker-compose ps
}

# Function to regenerate nginx config
regenerate_nginx() {
    echo "🌐 Regenerating nginx config..."
    cd "$PROJECT_DIR"
    
    if [ -f "generate-nginx-config.sh" ]; then
        chmod +x generate-nginx-config.sh
        ./generate-nginx-config.sh
        echo "✅ Nginx config regenerated"
    else
        echo "❌ generate-nginx-config.sh not found"
    fi
}

# Function to fix SSL certificates
fix_ssl() {
    echo "🔒 Fixing SSL certificates..."
    
    if [ -z "$PRIMARY_DOMAIN" ] || [ -z "$CMS_DOMAIN" ] || [ -z "$SSL_EMAIL" ]; then
        echo "❌ Missing environment variables for SSL"
        echo "   Please set PRIMARY_DOMAIN, CMS_DOMAIN, and SSL_EMAIL"
        return 1
    fi
    
    # Stop nginx to free port 80
    sudo systemctl stop nginx 2>/dev/null || true
    
    # Try to renew certificates
    echo "Renewing SSL certificates..."
    sudo certbot renew --dry-run
    
    # If dry-run fails, try to generate new certificates
    if [ $? -ne 0 ]; then
        echo "Trying to generate new certificates..."
        sudo certbot certonly --standalone --non-interactive --agree-tos -m "$SSL_EMAIL" -d "$PRIMARY_DOMAIN" -d "$CMS_DOMAIN"
    fi
}

# Function to restore from backup
restore_backup() {
    echo "📦 Available backups:"
    ls -la /home/backup-* 2>/dev/null || echo "No backups found"
    
    echo ""
    echo "Enter backup directory to restore from (or press Enter to skip):"
    read backup_dir
    
    if [ -n "$backup_dir" ] && [ -d "$backup_dir" ]; then
        echo "Restoring from $backup_dir..."
        
        # Restore .env
        if [ -f "$backup_dir/.env" ]; then
            cp "$backup_dir/.env" "$PROJECT_DIR/"
            echo "✅ .env restored"
        fi
        
        # Restore nginx config
        if [ -d "$backup_dir/nginx" ]; then
            cp -r "$backup_dir/nginx" "$PROJECT_DIR/"
            echo "✅ nginx config restored"
        fi
        
        # Restore WordPress files
        if [ -d "$backup_dir/wp" ]; then
            cp -r "$backup_dir/wp" "$PROJECT_DIR/"
            echo "✅ WordPress files restored"
        fi
    fi
}

# Function to clean start
clean_start() {
    echo "🧹 Clean start - this will remove everything and start fresh!"
    echo "⚠️  WARNING: This will delete all data!"
    echo "Type 'YES' to confirm:"
    read confirm
    
    if [ "$confirm" = "YES" ]; then
        echo "Removing project directory..."
        rm -rf "$PROJECT_DIR"
        
        echo "Removing lock file..."
        rm -f /tmp/setup-vps.lock
        
        echo "✅ Clean start ready. Run setup-vps-safe.sh again."
    else
        echo "Clean start cancelled."
    fi
}

# Main menu
show_menu() {
    echo ""
    echo "Choose an option:"
    echo "1) Diagnose issues"
    echo "2) Remove lock file"
    echo "3) Restart containers"
    echo "4) Regenerate nginx config"
    echo "5) Fix SSL certificates"
    echo "6) Restore from backup"
    echo "7) Clean start (DANGEROUS)"
    echo "8) Exit"
    echo ""
    echo "Enter your choice (1-8):"
}

# Main execution
main() {
    while true; do
        show_menu
        read choice
        
        case $choice in
            1)
                diagnose_issues
                ;;
            2)
                remove_lock
                ;;
            3)
                restart_containers
                ;;
            4)
                regenerate_nginx
                ;;
            5)
                fix_ssl
                ;;
            6)
                restore_backup
                ;;
            7)
                clean_start
                ;;
            8)
                echo "Goodbye!"
                exit 0
                ;;
            *)
                echo "Invalid choice. Please try again."
                ;;
        esac
        
        echo ""
        echo "Press Enter to continue..."
        read
    done
}

# Run main function
main "$@" 