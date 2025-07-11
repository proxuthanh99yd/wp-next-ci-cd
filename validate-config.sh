#!/bin/bash

# Load environment variables
if [ -f ".env" ]; then
    echo "📁 Loading .env file..."
    set -a  # automatically export all variables
    source .env 2>/dev/null || true
    set +a  # turn off automatic export
    echo "✅ .env file loaded"
else
    echo "❌ .env file not found!"
    exit 1
fi

echo "🔍 Validating configuration..."

# Debug: Show loaded variables
echo "📋 Debug - Loaded variables:"
echo "   NEXTJS_DOMAINS: '$NEXTJS_DOMAINS'"
echo "   PRIMARY_DOMAIN: '$PRIMARY_DOMAIN'"
echo "   CMS_DOMAIN: '$CMS_DOMAIN'"

# Check required environment variables
required_vars=(
    "MYSQL_ROOT_PASSWORD"
    "MYSQL_DATABASE" 
    "MYSQL_USER"
    "MYSQL_PASSWORD"
    "WORDPRESS_DB_NAME"
    "WORDPRESS_DB_USER"
    "WORDPRESS_DB_PASSWORD"
    "NEXTJS_DOMAINS"
    "PRIMARY_DOMAIN"
    "CMS_DOMAIN"
    "SSL_EMAIL"
    "PROJECT_NAME"
    "SSH_USER"
)

missing_vars=()
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        missing_vars+=("$var")
    fi
done

if [ ${#missing_vars[@]} -ne 0 ]; then
    echo "❌ Missing required environment variables:"
    printf '%s\n' "${missing_vars[@]}"
    exit 1
fi

# Validate domain format (supports subdomains)
if [[ ! "$PRIMARY_DOMAIN" =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]]; then
    echo "❌ Invalid PRIMARY_DOMAIN format: $PRIMARY_DOMAIN"
    exit 1
fi

if [[ ! "$CMS_DOMAIN" =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]]; then
    echo "❌ Invalid CMS_DOMAIN format: $CMS_DOMAIN"
    exit 1
fi

# Validate email format
if [[ ! "$SSL_EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
    echo "❌ Invalid SSL_EMAIL format: $SSL_EMAIL"
    exit 1
fi

# Check if SSL certificates exist
if [ ! -f "/etc/letsencrypt/live/$PRIMARY_DOMAIN/fullchain.pem" ]; then
    echo "⚠️  SSL certificate for $PRIMARY_DOMAIN not found"
    echo "   Run: sudo certbot certonly --standalone -d $PRIMARY_DOMAIN -d $CMS_DOMAIN"
fi

if [ ! -f "/etc/letsencrypt/live/$CMS_DOMAIN/fullchain.pem" ]; then
    echo "⚠️  SSL certificate for $CMS_DOMAIN not found"
    echo "   Run: sudo certbot certonly --standalone -d $PRIMARY_DOMAIN -d $CMS_DOMAIN"
fi

# Check Docker and Docker Compose
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not installed"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose not installed"
    exit 1
fi

# Check required files
required_files=(
    "docker-compose.yml"
    "generate-nginx-config.sh"
    "nextjs-app/Dockerfile"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Required file not found: $file"
        exit 1
    fi
done

echo "✅ Configuration validation passed!"
echo "📋 Summary:"
echo "   Primary Domain: $PRIMARY_DOMAIN"
echo "   CMS Domain: $CMS_DOMAIN"
echo "   Next.js Domains: $NEXTJS_DOMAINS"
echo "   SSL Email: $SSL_EMAIL" 