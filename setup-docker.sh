#!/bin/bash

# Docker and Certbot Installation Module
# This module installs Docker, Docker Compose, and Certbot

echo "🐳 Installing Docker and Certbot..."

# Update system packages
echo "📦 Updating system packages..."
sudo apt update

# Install Docker
echo "🐳 Installing Docker..."
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo apt install -y docker.io
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    echo "✅ Docker installed successfully"
else
    echo "✅ Docker already installed"
fi

# Install Docker Compose
echo "📦 Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    sudo apt install -y docker-compose
    echo "✅ Docker Compose installed successfully"
else
    echo "✅ Docker Compose already installed"
fi

# Install Git (if not already installed)
echo "📦 Installing Git..."
if ! command -v git &> /dev/null; then
    echo "Installing Git..."
    sudo apt install -y git
    echo "✅ Git installed successfully"
else
    echo "✅ Git already installed"
fi

# Install Certbot
echo "🔒 Installing Certbot..."
if ! command -v certbot &> /dev/null; then
    echo "Installing Certbot..."
    sudo apt install -y certbot
    echo "✅ Certbot installed successfully"
else
    echo "✅ Certbot already installed"
fi

# Verify installations
echo "🔍 Verifying installations..."

# Check Docker
if docker --version; then
    echo "✅ Docker verification: OK"
else
    echo "❌ Docker verification failed"
    exit 1
fi

# Check Docker Compose
if docker-compose --version; then
    echo "✅ Docker Compose verification: OK"
else
    echo "❌ Docker Compose verification failed"
    exit 1
fi

# Check Git
if git --version; then
    echo "✅ Git verification: OK"
else
    echo "❌ Git verification failed"
    exit 1
fi

# Check Certbot
if certbot --version; then
    echo "✅ Certbot verification: OK"
else
    echo "❌ Certbot verification failed"
    exit 1
fi

echo "✅ Docker and Certbot setup completed" 