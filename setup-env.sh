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
NEXTJS_DOMAIN="${NEXTJS_DOMAINS:-domain1.com domain2.com domain3.com}"
CMS_DOMAIN="${CMS_DOMAIN:-cms.domain1.com}"
SSL_EMAIL="${SSL_EMAIL:-your@email.com}"

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

# Handle NextJS app directory
if [ -d "nextjs-app" ]; then
    echo "ℹ️  nextjs-app directory already exists"
    
    # Check if it's a git repository
    if [ -d "nextjs-app/.git" ]; then
        echo "✅ nextjs-app is a git repository"
        
        # Check if .env exists in nextjs-app
        if [ -f "nextjs-app/.env" ]; then
            echo "✅ .env file found in nextjs-app"
        else
            echo "⚠️  .env file not found in nextjs-app"
            echo "   Please create .env file in nextjs-app directory"
        fi
        
        # Check if package.json exists (indicates it's a Node.js project)
        if [ -f "nextjs-app/package.json" ]; then
            echo "✅ package.json found in nextjs-app"
        else
            echo "⚠️  package.json not found in nextjs-app"
            echo "   This might not be a valid NextJS project"
        fi
    else
        echo "⚠️  nextjs-app directory exists but is not a git repository"
        echo "   This might be a manually created directory"
    fi
    
    # Skip cloning if directory exists
    echo "ℹ️  Skipping NextJS repo clone (directory already exists)"
    
elif [ ! -z "$NEXTJS_REPO" ]; then
    # Clone NextJS repo only if directory doesn't exist and repo URL is provided
    echo "🚀 Cloning NextJS repo: $NEXTJS_REPO"
    if git clone "$NEXTJS_REPO" nextjs-app; then
        echo "✅ NextJS repo cloned successfully"
        
        # Check if .env exists in cloned repo
        if [ -f "nextjs-app/.env" ]; then
            echo "✅ .env file found in cloned nextjs-app"
        else
            echo "⚠️  .env file not found in cloned nextjs-app"
            echo "   You may need to create .env file manually"
        fi
    else
        echo "❌ Failed to clone NextJS repo: $NEXTJS_REPO"
        echo "   Please check the repository URL and your git access"
        exit 1
    fi
else
    echo "ℹ️  No NextJS repo configured (NEXTJS_REPO not set in .env)"
    echo "   Skipping NextJS setup"
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

echo "✅ Environment setup completed" 