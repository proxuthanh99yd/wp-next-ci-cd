#!/bin/bash

# Enable SSL for WordPress + NextJS
# This script enables HTTPS by uncommenting SSL configurations

echo "🔒 Enabling SSL/HTTPS..."

# Load environment variables
if [ -f ".env" ]; then
    source .env
fi

# Tự động tạo SSL certificate nếu chưa có
if [ ! -f "/etc/letsencrypt/live/${PRIMARY_DOMAIN}/fullchain.pem" ] || [ ! -f "/etc/letsencrypt/live/${CMS_DOMAIN}/fullchain.pem" ]; then
    echo "🔒 Generating SSL certificates (if needed)..."
    sudo certbot certonly --standalone --non-interactive --agree-tos -m "$SSL_EMAIL" -d "$PRIMARY_DOMAIN" -d "$CMS_DOMAIN"
fi

# Check if SSL certificates exist
echo "🔍 Checking SSL certificates..."

if [ -f "/etc/letsencrypt/live/${PRIMARY_DOMAIN}/fullchain.pem" ]; then
    echo "✅ SSL certificate for ${PRIMARY_DOMAIN} found"
else
    echo "❌ SSL certificate for ${PRIMARY_DOMAIN} not found!"
    echo "   Please run: sudo certbot certonly --standalone -d ${PRIMARY_DOMAIN} -d ${CMS_DOMAIN}"
    exit 1
fi

if [ -f "/etc/letsencrypt/live/${CMS_DOMAIN}/fullchain.pem" ]; then
    echo "✅ SSL certificate for ${CMS_DOMAIN} found"
else
    echo "❌ SSL certificate for ${CMS_DOMAIN} not found!"
    echo "   Please run: sudo certbot certonly --standalone -d ${CMS_DOMAIN}"
    exit 1
fi

# Backup current nginx config
echo "💾 Backing up current nginx config..."
cp nginx/default.conf nginx/default.conf.backup

# Enable HTTPS configurations
echo "🔄 Enabling HTTPS configurations..."

# Create new nginx config with SSL enabled
cat > nginx/default.conf << 'EOF'
# Security headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

# Gzip compression
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_proxied expired no-cache no-store private auth;
gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss;

# HTTP to HTTPS redirect for CMS
server {
    listen 80;
    server_name ${CMS_DOMAIN};
    return 301 https://$host$request_uri;
}

# HTTP to HTTPS redirect for NextJS
server {
    listen 80;
    server_name ${NEXTJS_DOMAIN};
    return 301 https://$host$request_uri;
}

# CMS HTTPS access
server {
    listen 443 ssl http2;
    server_name ${CMS_DOMAIN};
    root /var/www/html;
    index index.php index.html;

    ssl_certificate /etc/letsencrypt/live/${CMS_DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${CMS_DOMAIN}/privkey.pem;

    # SSL security settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }
    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass wordpress:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_read_timeout 300;
    }

    # Deny access to sensitive files
    location ~ /\. {
        deny all;
    }
    location ~ ~$ {
        deny all;
    }
}

# Next.js domains with SSL
server {
    listen 443 ssl http2;
    server_name ${NEXTJS_DOMAIN};
    ssl_certificate /etc/letsencrypt/live/${PRIMARY_DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${PRIMARY_DOMAIN}/privkey.pem;

    # SSL security settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    location / {
        proxy_pass http://nextjs:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;

        # Timeout settings
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check endpoint
    location /api/health {
        proxy_pass http://nextjs:3000/api/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Verify nginx configuration
echo "🔍 Verifying nginx configuration..."
if docker exec nginx nginx -t; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration is invalid"
    echo "Restoring backup..."
    cp nginx/default.conf.backup nginx/default.conf
    exit 1
fi

# Reload nginx
echo "🔄 Reloading nginx..."
docker exec nginx nginx -s reload

echo "✅ SSL/HTTPS enabled successfully!"
echo ""
echo "🌐 Your sites are now available at:"
echo "   CMS: https://${CMS_DOMAIN}"
echo "   NextJS: https://${NEXTJS_DOMAIN}"
echo ""
echo "📝 SSL certificates will auto-renew every 90 days" 