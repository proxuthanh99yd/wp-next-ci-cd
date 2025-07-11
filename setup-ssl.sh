#!/bin/bash

# SSL Certificates Setup Module
# This module generates SSL certificates (Certbot should be installed via setup-docker.sh)

echo "🔒 Setting up SSL certificates..."

# Check if certbot is available
if ! command -v certbot &> /dev/null; then
    echo "❌ Certbot not found!"
    echo "   Please run setup-docker.sh first to install Certbot"
    exit 1
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

echo "✅ SSL setup completed" 