#!/bin/bash

# Now build and start NextJS
echo -e "\n🚀 Building and starting NextJS..."

# Check if nextjs-app directory exists
if [ ! -d "nextjs-app" ]; then
    echo "❌ nextjs-app directory not found!"
    echo "Please ensure NextJS project is properly set up"
    exit 1
fi

# Check if Dockerfile exists
if [ ! -f "nextjs-app/Dockerfile" ]; then
    echo "❌ Dockerfile not found in nextjs-app!"
    echo "Please ensure Dockerfile is present"
    exit 1
fi

# Build NextJS container
echo "🔨 Building NextJS container..."
docker-compose build nextjs

# Start NextJS container
echo "🚀 Starting NextJS container..."
docker-compose up -d nextjs

# Wait for NextJS to be ready
echo -e "\n⏳ Waiting for NextJS to be ready..."
sleep 30

# Check if NextJS is running
if docker ps | grep -q "nextjs"; then
    echo "✅ NextJS container is running"
else
    echo "❌ NextJS container failed to start"
    docker-compose logs nextjs
    exit 1
fi

# Test health check
echo "🏥 Testing NextJS health check..."
for i in {1..10}; do
    if curl -f http://localhost:3000/api/health >/dev/null 2>&1; then
        echo "✅ NextJS health check passed"
        break
    else
        echo "⏳ Waiting for NextJS to be healthy... (attempt $i/10)"
        sleep 10
    fi
done

echo "✅ NextJS setup completed" 