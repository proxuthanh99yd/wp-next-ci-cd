#!/bin/bash

# Load environment variables
if [ -f ".env" ]; then
    set -a  # automatically export all variables
    source .env 2>/dev/null || true
    set +a  # turn off automatic export
fi

# Default values
NEXTJS_DOMAINS="${NEXTJS_DOMAINS:-domain1.com domain2.com domain3.com}"
PRIMARY_DOMAIN="${PRIMARY_DOMAIN:-domain1.com}"
CMS_DOMAIN="${CMS_DOMAIN:-cms.domain1.com}"

# Generate main nginx config
cat > nginx/default.conf << EOF
# Main Nginx Configuration
# This file imports specific configurations for WordPress and NextJS

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
gzip_proxied expired no-cache no-store private must-revalidate auth;
gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss;

# Import WordPress configuration (enabled by default)
include /etc/nginx/wordpress.conf;

# Import NextJS configuration (commented out by default, will be enabled later)
# include /etc/nginx/nextjs.conf;
EOF

# Generate WordPress configuration
cat > nginx/wordpress.conf << EOF
# WordPress Nginx Configuration
# This file contains nginx configuration for WordPress

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
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    location ~ \.php\$ {
        include fastcgi_params;
        fastcgi_pass wordpress:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_read_timeout 300;
    }
    
    # Deny access to sensitive files
    location ~ /\. {
        deny all;
    }
    location ~ ~\$ {
        deny all;
    }
}

# CMS HTTP to HTTPS redirect
server {
    listen 80;
    server_name ${CMS_DOMAIN};
    return 301 https://\$host\$request_uri;
}
EOF

# Generate NextJS configuration
cat > nginx/nextjs.conf << EOF
# NextJS Nginx Configuration
# This file contains nginx configuration for NextJS

# Next.js domains with SSL
server {
    listen 443 ssl http2;
    server_name ${NEXTJS_DOMAINS};
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
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # Timeout settings
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}

# HTTP to HTTPS redirect for Next.js
server {
    listen 80;
    server_name ${NEXTJS_DOMAINS};
    return 301 https://\$host\$request_uri;
}
EOF

echo "✅ Nginx config files generated successfully!"
echo "Next.js Domains: ${NEXTJS_DOMAINS}"
echo "CMS Domain: ${CMS_DOMAIN}"
echo "Primary domain for SSL: ${PRIMARY_DOMAIN}"
echo ""
echo "Generated files:"
echo "  - nginx/default.conf (main config with imports)"
echo "  - nginx/wordpress.conf (WordPress specific config)"
echo "  - nginx/nextjs.conf (NextJS specific config)" 