#!/bin/bash

# SSH Keys Manager Script
# Interactive menu for SSH keys management

SSH_DIR="$HOME/.ssh"
PRIVATE_KEY="$SSH_DIR/id_rsa"
PUBLIC_KEY="$SSH_DIR/id_rsa.pub"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display menu
show_menu() {
    echo -e "${BLUE}=== SSH Keys Manager ===${NC}"
    echo ""
    echo "1. Check SSH keys status"
    echo "2. Generate new SSH keys"
    echo "3. Display public key"
    echo "4. Show key fingerprint"
    echo "5. Set proper permissions"
    echo "6. Backup SSH keys"
    echo "7. Exit"
    echo ""
    echo -n "Choose an option (1-7): "
}

# Function to check SSH keys status
check_status() {
    echo -e "${BLUE}=== SSH Keys Status ===${NC}"
    echo "SSH Directory: $SSH_DIR"
    echo ""
    
    # Check directory
    if [ -d "$SSH_DIR" ]; then
        echo -e "${GREEN}✓ SSH directory exists${NC}"
    else
        echo -e "${RED}✗ SSH directory not found${NC}"
    fi
    
    # Check private key
    if [ -f "$PRIVATE_KEY" ]; then
        echo -e "${GREEN}✓ Private key (id_rsa) found${NC}"
        echo "  Size: $(ls -lh "$PRIVATE_KEY" | awk '{print $5}')"
        echo "  Permissions: $(ls -l "$PRIVATE_KEY" | awk '{print $1}')"
    else
        echo -e "${RED}✗ Private key (id_rsa) not found${NC}"
    fi
    
    # Check public key
    if [ -f "$PUBLIC_KEY" ]; then
        echo -e "${GREEN}✓ Public key (id_rsa.pub) found${NC}"
        echo "  Size: $(ls -lh "$PUBLIC_KEY" | awk '{print $5}')"
        echo "  Permissions: $(ls -l "$PUBLIC_KEY" | awk '{print $1}')"
    else
        echo -e "${RED}✗ Public key (id_rsa.pub) not found${NC}"
    fi
    echo ""
}

# Function to generate SSH keys
generate_keys() {
    echo -e "${BLUE}=== Generating SSH Keys ===${NC}"
    
    # Create directory if needed
    if [ ! -d "$SSH_DIR" ]; then
        echo "Creating SSH directory..."
        mkdir -p "$SSH_DIR"
        chmod 700 "$SSH_DIR"
        echo -e "${GREEN}✓ SSH directory created${NC}"
    fi
    
    # Check if keys already exist
    if [ -f "$PRIVATE_KEY" ]; then
        echo -e "${YELLOW}⚠ SSH keys already exist${NC}"
        read -p "Do you want to overwrite them? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Operation cancelled."
            return
        fi
        rm -f "$PRIVATE_KEY" "$PUBLIC_KEY"
    fi
    
    echo "Generating new SSH key pair..."
    ssh-keygen -t rsa -b 4096 -f "$PRIVATE_KEY" -N "" -C "$(whoami)@$(hostname)"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ SSH key pair generated successfully${NC}"
        
        # Set proper permissions
        chmod 600 "$PRIVATE_KEY"
        chmod 644 "$PUBLIC_KEY"
        echo -e "${GREEN}✓ Permissions set correctly${NC}"
        
        # Show public key
        echo ""
        echo -e "${BLUE}=== Your Public Key ===${NC}"
        cat "$PUBLIC_KEY"
        echo ""
        echo -e "${YELLOW}Copy this public key to your server's authorized_keys file${NC}"
    else
        echo -e "${RED}✗ Failed to generate SSH key pair${NC}"
    fi
    echo ""
}

# Function to display public key
display_public_key() {
    if [ -f "$PUBLIC_KEY" ]; then
        echo -e "${BLUE}=== Public Key Content ===${NC}"
        cat "$PUBLIC_KEY"
        echo ""
        echo -e "${YELLOW}Copy this key to your server's ~/.ssh/authorized_keys file${NC}"
    else
        echo -e "${RED}✗ Public key not found${NC}"
        echo "Generate SSH keys first using option 2"
    fi
    echo ""
}

# Function to show fingerprint
show_fingerprint() {
    if [ -f "$PUBLIC_KEY" ]; then
        echo -e "${BLUE}=== Key Fingerprint ===${NC}"
        ssh-keygen -lf "$PUBLIC_KEY"
    else
        echo -e "${RED}✗ Public key not found${NC}"
        echo "Generate SSH keys first using option 2"
    fi
    echo ""
}

# Function to set permissions
set_permissions() {
    echo -e "${BLUE}=== Setting Permissions ===${NC}"
    
    if [ -d "$SSH_DIR" ]; then
        chmod 700 "$SSH_DIR"
        echo -e "${GREEN}✓ SSH directory permissions set${NC}"
    fi
    
    if [ -f "$PRIVATE_KEY" ]; then
        chmod 600 "$PRIVATE_KEY"
        echo -e "${GREEN}✓ Private key permissions set${NC}"
    fi
    
    if [ -f "$PUBLIC_KEY" ]; then
        chmod 644 "$PUBLIC_KEY"
        echo -e "${GREEN}✓ Public key permissions set${NC}"
    fi
    
    if [ ! -f "$PRIVATE_KEY" ] && [ ! -f "$PUBLIC_KEY" ]; then
        echo -e "${YELLOW}⚠ No SSH keys found to set permissions${NC}"
    fi
    echo ""
}

# Function to backup SSH keys
backup_keys() {
    echo -e "${BLUE}=== Backup SSH Keys ===${NC}"
    
    BACKUP_DIR="$HOME/ssh-backup-$(date +%Y%m%d-%H%M%S)"
    
    if [ -f "$PRIVATE_KEY" ] || [ -f "$PUBLIC_KEY" ]; then
        mkdir -p "$BACKUP_DIR"
        
        if [ -f "$PRIVATE_KEY" ]; then
            cp "$PRIVATE_KEY" "$BACKUP_DIR/"
            echo -e "${GREEN}✓ Private key backed up${NC}"
        fi
        
        if [ -f "$PUBLIC_KEY" ]; then
            cp "$PUBLIC_KEY" "$BACKUP_DIR/"
            echo -e "${GREEN}✓ Public key backed up${NC}"
        fi
        
        echo -e "${GREEN}✓ Backup created in: $BACKUP_DIR${NC}"
        echo -e "${YELLOW}⚠ Keep this backup secure!${NC}"
    else
        echo -e "${YELLOW}⚠ No SSH keys found to backup${NC}"
    fi
    echo ""
}

# Main menu loop
while true; do
    show_menu
    read -r choice
    
    case $choice in
        1)
            check_status
            ;;
        2)
            generate_keys
            ;;
        3)
            display_public_key
            ;;
        4)
            show_fingerprint
            ;;
        5)
            set_permissions
            ;;
        6)
            backup_keys
            ;;
        7)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please choose 1-7.${NC}"
            echo ""
            ;;
    esac
    
    if [ "$choice" != "7" ]; then
        read -p "Press Enter to continue..."
        echo ""
    fi
done 