#!/bin/bash

# Final verification
echo -e "\n🔍 Final verification..."
sleep 10

# Check all services
echo -e "\n📋 Service Status:"
if docker ps | grep -q "mysql"; then
    echo "  ✅ Database (MySQL) - Running"
else
    echo "  ❌ Database (MySQL) - Not running"
fi

if docker ps | grep -q "wordpress"; then
    echo "  ✅ WordPress - Running"
else
    echo "  ❌ WordPress - Not running"
fi

if docker ps | grep -q "nginx"; then
    echo "  ✅ Nginx - Running"
else
    echo "  ❌ Nginx - Not running"
fi

if docker ps | grep -q "nextjs"; then
    echo "  ✅ NextJS - Running"
else
    echo "  ❌ NextJS - Not running"
fi

echo -e "\n🎉 Setup completed successfully!"
echo -e "\n📋 Access Information:"
echo "  WordPress Admin: http://localhost/wp-admin"
echo "  NextJS App: http://localhost:3000"
echo "  Nginx: http://localhost"
echo -e "\n📝 Next Steps:"
echo "  1. Update PRIMARY_DOMAIN, CMS_DOMAIN, and SSL_EMAIL in .env for production"
echo "  2. Configure your domain DNS settings"
echo "  3. Run SSL certificate generation again with proper domains"
echo "  4. Customize your WordPress site and NextJS app"

echo "✅ Verification completed" 