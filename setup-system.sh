#!/bin/bash

# System Dependencies Setup Module
# This module installs basic system dependencies (excluding Docker and Certbot)

echo "🔧 Setting up system dependencies..."

# Update system packages
echo "📦 Updating system packages..."
sudo apt update

# Install additional system dependencies (if needed)
echo "📦 Installing additional system dependencies..."

# Install curl (if not already installed)
if ! command -v curl &> /dev/null; then
    echo "Installing curl..."
    sudo apt install -y curl
    echo "✅ curl installed successfully"
else
    echo "✅ curl already installed"
fi

# Install wget (if not already installed)
if ! command -v wget &> /dev/null; then
    echo "Installing wget..."
    sudo apt install -y wget
    echo "✅ wget installed successfully"
else
    echo "✅ wget already installed"
fi

# Install unzip (if not already installed)
if ! command -v unzip &> /dev/null; then
    echo "Installing unzip..."
    sudo apt install -y unzip
    echo "✅ unzip installed successfully"
else
    echo "✅ unzip already installed"
fi

# Install net-tools (for netstat command)
if ! command -v netstat &> /dev/null; then
    echo "Installing net-tools..."
    sudo apt install -y net-tools
    echo "✅ net-tools installed successfully"
else
    echo "✅ net-tools already installed"
fi

echo "✅ System dependencies setup completed" 