#!/bin/bash

# WordPress Plugin Installation Script
# This script installs plugins from the wp-plugin folder after WordPress is set up

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Default values
WORDPRESS_DB_NAME="${WORDPRESS_DB_NAME:-wordpress}"
WORDPRESS_DB_USER="${WORDPRESS_DB_USER:-wordpress}"
WORDPRESS_DB_PASSWORD="${WORDPRESS_DB_PASSWORD:-wordpress_password}"
WORDPRESS_DB_HOST="${WORDPRESS_DB_HOST:-db:3306}"

echo -e "${BLUE}🔧 WordPress Plugin Installation Script${NC}"
echo "=================================="

# Check if WordPress container is running
if ! docker ps | grep -q "wordpress"; then
    echo -e "${RED}❌ WordPress container is not running!${NC}"
    echo "Please start WordPress first with: docker-compose up -d"
    exit 1
fi

# Check and install WP-CLI if needed
if ! docker exec wordpress wp --version --allow-root 2>/dev/null; then
    echo -e "${BLUE}📦 WP-CLI not found. Installing...${NC}"
    if [ -f "setup-wp-cli.sh" ]; then
        chmod +x setup-wp-cli.sh
        ./setup-wp-cli.sh
    else
        echo -e "${YELLOW}⚠️  setup-wp-cli.sh not found. Installing WP-CLI manually...${NC}"
        docker exec wordpress curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
        docker exec wordpress chmod +x wp-cli.phar
        docker exec wordpress mv wp-cli.phar /usr/local/bin/wp
    fi
fi

# Check if wp-plugin folder exists
if [ ! -d "wp-plugin" ]; then
    echo -e "${YELLOW}⚠️  wp-plugin folder not found. Creating it...${NC}"
    mkdir -p wp-plugin
    echo -e "${GREEN}✅ wp-plugin folder created${NC}"
    exit 0
fi

# Check if there are any plugin files
PLUGIN_FILES=$(find wp-plugin -name "*.zip" -type f)
if [ -z "$PLUGIN_FILES" ]; then
    echo -e "${YELLOW}⚠️  No plugin files found in wp-plugin folder${NC}"
    echo "Please add .zip plugin files to the wp-plugin folder"
    exit 0
fi

echo -e "${GREEN}📦 Found plugin files:${NC}"
echo "$PLUGIN_FILES" | while read -r file; do
    echo "  - $(basename "$file")"
done

# Wait for WordPress to be fully ready
echo -e "${BLUE}⏳ Waiting for WordPress to be ready...${NC}"
sleep 10

# Function to check if WordPress is ready
check_wordpress_ready() {
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker exec wordpress wp core is-installed --allow-root 2>/dev/null; then
            return 0
        fi
        
        echo -e "${YELLOW}⏳ Attempt $attempt/$max_attempts: WordPress not ready yet...${NC}"
        sleep 10
        ((attempt++))
    done
    
    return 1
}

# Check if WordPress is ready
if ! check_wordpress_ready; then
    echo -e "${RED}❌ WordPress is not ready after waiting. Please check the container logs:${NC}"
    echo "docker logs wordpress"
    exit 1
fi

echo -e "${GREEN}✅ WordPress is ready!${NC}"

# Install plugins in specific order
echo -e "${BLUE}🚀 Installing plugins in order...${NC}"

# Define plugin installation order
declare -a plugins=(
    "all-in-one-wp-migration"
    "all-in-one-wp-migration-unlimited-extension"
)

# Install plugins in order
for plugin_name in "${plugins[@]}"; do
    plugin_file="wp-plugin/${plugin_name}.zip"
    if [ -f "$plugin_file" ]; then
        echo -e "${BLUE}📦 Installing $plugin_name...${NC}"
        
        # Copy plugin to WordPress container
        docker cp "$plugin_file" wordpress:/tmp/
        
        # Install plugin using WP-CLI
        if docker exec wordpress wp plugin install /tmp/"$(basename "$plugin_file")" --activate --allow-root; then
            echo -e "${GREEN}✅ $plugin_name installed and activated successfully${NC}"
            
            # Wait a moment for plugin to fully activate
            sleep 5
        else
            echo -e "${RED}❌ Failed to install $plugin_name${NC}"
        fi
        
        # Clean up temporary file
        docker exec wordpress rm -f /tmp/"$(basename "$plugin_file")"
    else
        echo -e "${YELLOW}⚠️  Plugin file not found: $plugin_file${NC}"
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
        
        echo -e "${BLUE}📦 Installing additional plugin: $plugin_name...${NC}"
        
        # Copy plugin to WordPress container
        docker cp "$plugin_file" wordpress:/tmp/
        
        # Install plugin using WP-CLI
        if docker exec wordpress wp plugin install /tmp/"$(basename "$plugin_file")" --activate --allow-root; then
            echo -e "${GREEN}✅ $plugin_name installed and activated successfully${NC}"
        else
            echo -e "${RED}❌ Failed to install $plugin_name${NC}"
        fi
        
        # Clean up temporary file
        docker exec wordpress rm -f /tmp/"$(basename "$plugin_file")"
    fi
done

# List installed plugins
echo -e "${BLUE}📋 Installed plugins:${NC}"
docker exec wordpress wp plugin list --status=active --allow-root

echo -e "${GREEN}🎉 Plugin installation completed!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Access your WordPress admin at: https://your-domain.com/wp-admin"
echo "2. Configure the installed plugins"
echo "3. Set up your site content" 