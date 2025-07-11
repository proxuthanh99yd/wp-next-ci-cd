#!/bin/bash

# SSH Keys Backup Script
# Backup id_rsa and id_rsa.pub files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default SSH directory
SSH_DIR="$HOME/.ssh"
BACKUP_DIR="./ssh-backup-$(date +%Y%m%d_%H%M%S)"

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

# Check if SSH directory exists
if [ ! -d "$SSH_DIR" ]; then
    print_error "SSH directory not found: $SSH_DIR"
    exit 1
fi

print_status "SSH directory found: $SSH_DIR"

# Create backup directory
mkdir -p "$BACKUP_DIR"
print_status "Created backup directory: $BACKUP_DIR"

# Function to backup SSH key
backup_ssh_key() {
    local key_file="$1"
    local key_path="$SSH_DIR/$key_file"
    
    if [ -f "$key_path" ]; then
        cp "$key_path" "$BACKUP_DIR/"
        print_status "Backed up: $key_file"
        
        # Display key info
        if [[ "$key_file" == *.pub ]]; then
            echo "Public key content:"
            cat "$key_path"
            echo ""
        fi
    else
        print_warning "SSH key not found: $key_file"
    fi
}

# Backup private and public keys
backup_ssh_key "id_rsa"
backup_ssh_key "id_rsa.pub"

# Check if keys were backed up
if [ -f "$BACKUP_DIR/id_rsa" ] || [ -f "$BACKUP_DIR/id_rsa.pub" ]; then
    print_status "Backup completed successfully!"
    echo "Backup location: $BACKUP_DIR"
    echo ""
    
    # List backed up files
    echo "Backed up files:"
    ls -la "$BACKUP_DIR/"
    echo ""
    
    # Set proper permissions for backup
    chmod 600 "$BACKUP_DIR/id_rsa" 2>/dev/null || true
    chmod 644 "$BACKUP_DIR/id_rsa.pub" 2>/dev/null || true
    
    print_status "Permissions set for backup files"
else
    print_error "No SSH keys found to backup"
    exit 1
fi

# Optional: Generate new SSH key if none exist
if [ ! -f "$SSH_DIR/id_rsa" ] && [ ! -f "$SSH_DIR/id_rsa.pub" ]; then
    echo ""
    read -p "No SSH keys found. Generate new SSH key pair? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Generating new SSH key pair..."
        ssh-keygen -t rsa -b 4096 -f "$SSH_DIR/id_rsa" -N ""
        print_status "New SSH key pair generated!"
        
        # Backup the newly generated keys
        backup_ssh_key "id_rsa"
        backup_ssh_key "id_rsa.pub"
    fi
fi

print_status "Script completed!" 