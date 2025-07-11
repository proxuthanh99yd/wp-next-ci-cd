#!/bin/bash

# Nginx Configuration for WordPress Module
# This module configures nginx for WordPress after WordPress is ready

echo "🌐 Configuring Nginx for WordPress..."

# Start nginx first (will serve static content and proxy to NextJS later)
echo -e "\n🚀 Starting nginx..."
# Start nginx without building other services
docker-compose up -d --no-deps nginx

# Wait a moment for nginx to start
sleep 5

# Check if nginx is running
if docker ps | grep -q "nginx"; then
    echo "✅ Nginx started successfully"
else
    echo "❌ Failed to start nginx"
    exit 1
fi

# Generate nginx config for WordPress (if not already done)
if [ ! -f "nginx/default.conf" ]; then
    echo "📝 Generating nginx configuration..."
    if [ -f "generate-nginx-config.sh" ]; then
        chmod +x generate-nginx-config.sh
        ./generate-nginx-config.sh
    else
        echo "❌ generate-nginx-config.sh not found"
        exit 1
    fi
fi

# Verify nginx configuration
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

echo "✅ Nginx WordPress configuration completed" 