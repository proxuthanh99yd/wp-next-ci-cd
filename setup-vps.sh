#!/bin/bash

# WordPress + NextJS VPS Setup Script
# This script sets up a complete WordPress + NextJS environment on a VPS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

echo "🚀 Starting WordPress + NextJS VPS Setup..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Make all setup scripts executable
chmod +x "$SCRIPT_DIR"/setup-*.sh

# Step 1: Get SSH Keys
print_step "Step 1: Getting SSH Keys..."
echo ""

# Run SSH keys script
if [ -f "$SCRIPT_DIR/get-ssh-keys.sh" ]; then
    print_status "Running SSH keys check..."
    bash "$SCRIPT_DIR/get-ssh-keys.sh"
    echo ""
else
    print_warning "SSH keys script not found, creating basic check..."
    SSH_DIR="$HOME/.ssh"
    
    if [ -f "$SSH_DIR/id_rsa" ] && [ -f "$SSH_DIR/id_rsa.pub" ]; then
        print_status "SSH keys found:"
        echo "Private key: $SSH_DIR/id_rsa"
        echo "Public key: $SSH_DIR/id_rsa.pub"
        echo ""
        echo "=== Private Key Content ==="
        cat "$SSH_DIR/id_rsa"
        echo ""
        echo "=== End Private Key ==="
        echo ""
        echo "=== Public Key Content ==="
        cat "$SSH_DIR/id_rsa.pub"
        echo ""
        echo "=== End Public Key ==="
        echo ""
    else
        print_warning "SSH keys not found in $SSH_DIR"
        echo "Please ensure you have SSH keys set up before continuing."
        echo ""
    fi
fi

# Wait for user confirmation before proceeding
echo "=========================================="
print_warning "Please review the SSH keys information above."
echo "Make sure you have access to your SSH keys before proceeding."
echo "=========================================="
echo ""

while true; do
    read -p "Do you want to continue with the setup? (y/n): " -n 1 -r
    echo
    case $REPLY in
        [Yy]* ) 
            print_status "Continuing with setup..."
            echo ""
            break
            ;;
        [Nn]* ) 
            print_error "Setup cancelled by user."
            exit 1
            ;;
        * ) 
            echo "Please answer y (yes) or n (no)."
            ;;
    esac
done

# Import and run setup modules
echo "📦 Setting up environment..."
source "$SCRIPT_DIR/setup-env.sh"

echo "🐳 Setting up Docker and Certbot..."
source "$SCRIPT_DIR/setup-docker.sh"

echo "🔧 Setting up system dependencies..."
source "$SCRIPT_DIR/setup-system.sh"

echo "🔒 Setting up SSL certificates..."
source "$SCRIPT_DIR/setup-ssl.sh"

echo "📝 Setting up WordPress..."
source "$SCRIPT_DIR/setup-wordpress.sh"

echo "🔌 Setting up WordPress plugins..."
source "$SCRIPT_DIR/setup-plugins.sh"

echo "💾 Setting up backup and restore..."
source "$SCRIPT_DIR/setup-backup.sh"

echo "🌐 Setting up Nginx for WordPress..."
source "$SCRIPT_DIR/setup-nginx-wordpress.sh"

echo "⚛️ Setting up NextJS..."
source "$SCRIPT_DIR/setup-nextjs.sh"

echo "🌐 Setting up Nginx for NextJS..."
source "$SCRIPT_DIR/setup-nginx-nextjs.sh"

echo "✅ Final verification..."
source "$SCRIPT_DIR/setup-verification.sh"

echo "🎉 All setup modules completed successfully!"
