#!/bin/bash

# Service Status Check Script
# This script checks the status of all services in the correct order

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Service Status Check${NC}"
echo "========================"

# Check if containers are running
echo -e "\n${BLUE}📦 Container Status:${NC}"

# Check database
if docker ps | grep -q "mysql"; then
    echo -e "  ${GREEN}✅ Database (MySQL) - Running${NC}"
else
    echo -e "  ${RED}❌ Database (MySQL) - Not running${NC}"
fi

# Check WordPress
if docker ps | grep -q "wordpress"; then
    echo -e "  ${GREEN}✅ WordPress - Running${NC}"
    
    # Check if WordPress is fully functional
    if docker exec wordpress wp core is-installed --allow-root 2>/dev/null; then
        echo -e "  ${GREEN}✅ WordPress - Fully functional${NC}"
    else
        echo -e "  ${YELLOW}⚠️  WordPress - Running but not fully ready${NC}"
    fi
else
    echo -e "  ${RED}❌ WordPress - Not running${NC}"
fi

# Check NextJS
if docker ps | grep -q "nextjs"; then
    echo -e "  ${GREEN}✅ NextJS - Running${NC}"
    
    # Check if NextJS is responding
    if curl -f http://localhost:3000/api/health 2>/dev/null; then
        echo -e "  ${GREEN}✅ NextJS - Health check passed${NC}"
    else
        echo -e "  ${YELLOW}⚠️  NextJS - Running but health check failed${NC}"
    fi
else
    echo -e "  ${RED}❌ NextJS - Not running${NC}"
fi

# Check nginx
if docker ps | grep -q "nginx"; then
    echo -e "  ${GREEN}✅ Nginx - Running${NC}"
else
    echo -e "  ${RED}❌ Nginx - Not running${NC}"
fi

# Check WordPress plugins
echo -e "\n${BLUE}🔌 WordPress Plugins:${NC}"
if docker ps | grep -q "wordpress" && docker exec wordpress wp --version --allow-root 2>/dev/null; then
    docker exec wordpress wp plugin list --status=active --allow-root 2>/dev/null || echo -e "  ${YELLOW}⚠️  No active plugins or WP-CLI not available${NC}"
else
    echo -e "  ${RED}❌ Cannot check plugins - WordPress not available${NC}"
fi

# Check ports
echo -e "\n${BLUE}🌐 Port Status:${NC}"
if netstat -tuln | grep -q ":80 "; then
    echo -e "  ${GREEN}✅ Port 80 (HTTP) - Open${NC}"
else
    echo -e "  ${RED}❌ Port 80 (HTTP) - Closed${NC}"
fi

if netstat -tuln | grep -q ":443 "; then
    echo -e "  ${GREEN}✅ Port 443 (HTTPS) - Open${NC}"
else
    echo -e "  ${RED}❌ Port 443 (HTTPS) - Closed${NC}"
fi

if netstat -tuln | grep -q ":3000 "; then
    echo -e "  ${GREEN}✅ Port 3000 (NextJS) - Open${NC}"
else
    echo -e "  ${RED}❌ Port 3000 (NextJS) - Closed${NC}"
fi

# Check SSL certificates
echo -e "\n${BLUE}🔒 SSL Certificates:${NC}"
if [ -f "/etc/letsencrypt/live/$(grep PRIMARY_DOMAIN .env | cut -d'=' -f2)/fullchain.pem" ]; then
    echo -e "  ${GREEN}✅ Primary domain SSL - Valid${NC}"
else
    echo -e "  ${RED}❌ Primary domain SSL - Not found${NC}"
fi

if [ -f "/etc/letsencrypt/live/$(grep CMS_DOMAIN .env | cut -d'=' -f2)/fullchain.pem" ]; then
    echo -e "  ${GREEN}✅ CMS domain SSL - Valid${NC}"
else
    echo -e "  ${RED}❌ CMS domain SSL - Not found${NC}"
fi

echo -e "\n${BLUE}📋 Quick Commands:${NC}"
echo "  View logs: docker logs <container_name>"
echo "  Restart service: docker-compose restart <service_name>"
echo "  Stop all: docker-compose down"
echo "  Start all: docker-compose up -d" 