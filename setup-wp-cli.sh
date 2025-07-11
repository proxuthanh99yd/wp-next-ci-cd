#!/bin/bash

# WP-CLI Installation Script for WordPress Container
# This script installs WP-CLI in the WordPress container

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 WP-CLI Installation Script${NC}"
echo "=============================="

# Check if WordPress container is running
if ! docker ps | grep -q "wordpress"; then
    echo -e "${RED}❌ WordPress container is not running!${NC}"
    echo "Please start WordPress first with: docker-compose up -d"
    exit 1
fi

# Check if WP-CLI is already installed
if docker exec wordpress wp --version --allow-root 2>/dev/null; then
    echo -e "${GREEN}✅ WP-CLI is already installed${NC}"
    docker exec wordpress wp --version --allow-root
    exit 0
fi

echo -e "${BLUE}📦 Installing WP-CLI...${NC}"

# Download and install WP-CLI
docker exec wordpress curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
docker exec wordpress chmod +x wp-cli.phar
docker exec wordpress mv wp-cli.phar /usr/local/bin/wp

# Verify installation
if docker exec wordpress wp --version --allow-root; then
    echo -e "${GREEN}✅ WP-CLI installed successfully!${NC}"
else
    echo -e "${RED}❌ WP-CLI installation failed!${NC}"
    exit 1
fi

echo -e "${BLUE}📋 WP-CLI commands available:${NC}"
echo "  - wp plugin install <plugin.zip> --activate"
echo "  - wp plugin list"
echo "  - wp theme install <theme.zip> --activate"
echo "  - wp core update"
echo "  - wp db export"
echo "  - wp db import <file.sql>" 