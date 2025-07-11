#!/bin/bash

# SSH Keys Management Script
# Get and display id_rsa and id_rsa.pub content
# Optionally generate keys if they don't exist

SSH_DIR="$HOME/.ssh"
PRIVATE_KEY="$SSH_DIR/id_rsa"
PUBLIC_KEY="$SSH_DIR/id_rsa.pub"

# Check if user wants to generate keys
GENERATE_KEYS=false
if [ "$1" = "--generate" ] || [ "$1" = "-g" ]; then
    GENERATE_KEYS=true
fi

echo "=== SSH Keys Information ==="
echo "SSH Directory: $SSH_DIR"
echo ""

# Create .ssh directory if it doesn't exist
if [ ! -d "$SSH_DIR" ]; then
    echo "Creating SSH directory..."
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    echo "✓ SSH directory created"
    echo ""
fi

# Check private key
if [ -f "$PRIVATE_KEY" ]; then
    echo "✓ Private key (id_rsa) found"
    echo "File size: $(ls -lh "$PRIVATE_KEY" | awk '{print $5}')"
    echo "Permissions: $(ls -l "$PRIVATE_KEY" | awk '{print $1}')"
    echo ""
    echo "=== Private Key Content ==="
    cat "$PRIVATE_KEY"
    echo ""
    echo "=== End Private Key ==="
    echo ""
else
    echo "✗ Private key (id_rsa) not found"
    echo ""
    
    if [ "$GENERATE_KEYS" = true ]; then
        echo "Generating new SSH key pair..."
        ssh-keygen -t rsa -b 4096 -f "$PRIVATE_KEY" -N "" -C "$(whoami)@$(hostname)"
        
        if [ $? -eq 0 ]; then
            echo "✓ SSH key pair generated successfully"
            echo "File size: $(ls -lh "$PRIVATE_KEY" | awk '{print $5}')"
            echo "Permissions: $(ls -l "$PRIVATE_KEY" | awk '{print $1}')"
            echo ""
            echo "=== Private Key Content ==="
            cat "$PRIVATE_KEY"
            echo ""
            echo "=== End Private Key ==="
            echo ""
            
            # Set proper permissions
            chmod 600 "$PRIVATE_KEY"
            chmod 644 "$PUBLIC_KEY"
        else
            echo "✗ Failed to generate SSH key pair"
            exit 1
        fi
    else
        echo "To generate SSH keys, run: $0 --generate"
        echo ""
    fi
fi

# Check public key
if [ -f "$PUBLIC_KEY" ]; then
    echo "✓ Public key (id_rsa.pub) found"
    echo "File size: $(ls -lh "$PUBLIC_KEY" | awk '{print $5}')"
    echo "Permissions: $(ls -l "$PUBLIC_KEY" | awk '{print $1}')"
    echo ""
    echo "=== Public Key Content ==="
    cat "$PUBLIC_KEY"
    echo ""
    echo "=== End Public Key ==="
    echo ""
else
    echo "✗ Public key (id_rsa.pub) not found"
    echo ""
fi

# Show key fingerprint if available
if [ -f "$PUBLIC_KEY" ]; then
    echo "=== Key Fingerprint ==="
    ssh-keygen -lf "$PUBLIC_KEY"
    echo ""
fi

echo "=== Script completed ==="

# Show usage information
if [ "$GENERATE_KEYS" = false ]; then
    echo ""
    echo "=========================================="
    echo "[INFO] Usage:"
    echo "  $0              - Check SSH keys status"
    echo "  $0 --generate   - Generate SSH keys if missing"
    echo "  $0 -g           - Short form for generate"
    echo "=========================================="
fi 