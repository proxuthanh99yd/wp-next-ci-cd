#!/bin/bash

# Nginx Configuration for NextJS Module
# This module configures nginx for NextJS after NextJS is ready

echo "🌐 Configuring Nginx for NextJS..."

# Wait for NextJS to be ready before enabling nginx config
echo -e "\n⏳ Waiting for NextJS to be ready..."
sleep 10

# Check if NextJS is running
if docker ps | grep -q "nextjs"; then
    echo "✅ NextJS is running"
else
    echo "❌ NextJS is not running"
    exit 1
fi

# Enable NextJS nginx config by uncommenting the include line
echo -e "\n🔄 Enabling NextJS nginx configuration..."
# No need to uncomment since we're using single config file now
echo "✅ NextJS nginx configuration is already enabled in default.conf"

# Verify nginx configuration after changes
echo "🔍 Verifying nginx configuration..."
if docker exec nginx nginx -t; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration is invalid"
    exit 1
fi

# Reload nginx configuration
echo "🔄 Reloading nginx configuration..."
docker exec nginx nginx -s reload

echo "✅ Nginx NextJS configuration completed" 