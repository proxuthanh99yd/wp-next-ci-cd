#!/bin/bash

# Setup SSH Server Script
# Configure SSH server and authorized_keys

SSH_DIR="$HOME/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== SSH Server Setup Script ===${NC}"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${YELLOW}⚠ Running as root. Consider running as regular user.${NC}"
    echo ""
fi

# Create .ssh directory if it doesn't exist
if [ ! -d "$SSH_DIR" ]; then
    echo "Creating SSH directory..."
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    echo -e "${GREEN}✓ SSH directory created${NC}"
    echo ""
fi

# Check if authorized_keys exists
if [ ! -f "$AUTHORIZED_KEYS" ]; then
    echo "Creating authorized_keys file..."
    touch "$AUTHORIZED_KEYS"
    chmod 600 "$AUTHORIZED_KEYS"
    echo -e "${GREEN}✓ authorized_keys file created${NC}"
    echo ""
fi

# Function to add public key
add_public_key() {
    local public_key="$1"
    
    if [ -z "$public_key" ]; then
        echo -e "${RED}✗ No public key provided${NC}"
        return 1
    fi
    
    # Check if key already exists
    if grep -q "$public_key" "$AUTHORIZED_KEYS" 2>/dev/null; then
        echo -e "${YELLOW}⚠ Public key already exists in authorized_keys${NC}"
        return 0
    fi
    
    # Add key to authorized_keys
    echo "$public_key" >> "$AUTHORIZED_KEYS"
    echo -e "${GREEN}✓ Public key added to authorized_keys${NC}"
    return 0
}

# Check if public key is provided as argument
if [ $# -eq 1 ]; then
    echo "Adding provided public key..."
    add_public_key "$1"
    echo ""
else
    echo -e "${YELLOW}No public key provided as argument${NC}"
    echo "You can:"
    echo "1. Run with public key: $0 'ssh-rsa AAAA...'"
    echo "2. Manually edit: $AUTHORIZED_KEYS"
    echo "3. Use interactive mode below"
    echo ""
    
    # Interactive mode
    read -p "Do you want to add a public key interactively? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Paste your public key (press Enter when done):"
        read -r public_key
        if [ ! -z "$public_key" ]; then
            add_public_key "$public_key"
        fi
    fi
fi

# Set proper permissions
echo "Setting proper permissions..."
chmod 700 "$SSH_DIR"
chmod 600 "$AUTHORIZED_KEYS"
echo -e "${GREEN}✓ Permissions set correctly${NC}"
echo ""

# Show current authorized_keys content
echo -e "${BLUE}=== Current authorized_keys ===${NC}"
if [ -s "$AUTHORIZED_KEYS" ]; then
    cat "$AUTHORIZED_KEYS"
    echo ""
    echo "Number of authorized keys: $(wc -l < "$AUTHORIZED_KEYS")"
else
    echo -e "${YELLOW}⚠ authorized_keys is empty${NC}"
    echo "Add your public key to enable SSH access"
fi
echo ""

# SSH server configuration recommendations
echo -e "${BLUE}=== SSH Server Configuration ===${NC}"
echo "Recommended SSH server settings (/etc/ssh/sshd_config):"
echo ""
echo "PasswordAuthentication no"
echo "PubkeyAuthentication yes"
echo "AuthorizedKeysFile .ssh/authorized_keys"
echo "PermitRootLogin no"
echo "Port 22"
echo ""

# Check SSH service status
if command -v systemctl >/dev/null 2>&1; then
    echo -e "${BLUE}=== SSH Service Status ===${NC}"
    if systemctl is-active --quiet ssh; then
        echo -e "${GREEN}✓ SSH service is running${NC}"
    else
        echo -e "${RED}✗ SSH service is not running${NC}"
        echo "Start with: sudo systemctl start ssh"
    fi
    
    if systemctl is-enabled --quiet ssh; then
        echo -e "${GREEN}✓ SSH service is enabled${NC}"
    else
        echo -e "${YELLOW}⚠ SSH service is not enabled${NC}"
        echo "Enable with: sudo systemctl enable ssh"
    fi
    echo ""
fi

# Security recommendations
echo -e "${BLUE}=== Security Recommendations ===${NC}"
echo "1. Disable password authentication: PasswordAuthentication no"
echo "2. Use key-based authentication only"
echo "3. Change default SSH port (optional)"
echo "4. Use fail2ban to prevent brute force attacks"
echo "5. Keep authorized_keys file secure (chmod 600)"
echo "6. Regularly rotate SSH keys"
echo ""

echo -e "${GREEN}✓ SSH server setup completed${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Test SSH connection from client"
echo "2. Configure SSH server settings"
echo "3. Set up fail2ban (recommended)"
echo "4. Consider changing SSH port" 