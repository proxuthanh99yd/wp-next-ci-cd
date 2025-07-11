#!/bin/bash

# Generate SSH Keys Script
# Automatically generate SSH keys if they don't exist

SSH_DIR="$HOME/.ssh"
PRIVATE_KEY="$SSH_DIR/id_rsa"
PUBLIC_KEY="$SSH_DIR/id_rsa.pub"

echo "=== SSH Keys Generation Script ==="
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

# Check if private key exists
if [ -f "$PRIVATE_KEY" ]; then
    echo "✓ Private key (id_rsa) already exists"
    echo "File size: $(ls -lh "$PRIVATE_KEY" | awk '{print $5}')"
    echo "Permissions: $(ls -l "$PRIVATE_KEY" | awk '{print $1}')"
    echo ""
else
    echo "✗ Private key (id_rsa) not found"
    echo "Generating new SSH key pair..."
    echo ""
    
    # Generate SSH key pair
    ssh-keygen -t rsa -b 4096 -f "$PRIVATE_KEY" -N "" -C "$(whoami)@$(hostname)"
    
    if [ $? -eq 0 ]; then
        echo "✓ SSH key pair generated successfully"
        echo "File size: $(ls -lh "$PRIVATE_KEY" | awk '{print $5}')"
        echo "Permissions: $(ls -l "$PRIVATE_KEY" | awk '{print $1}')"
        echo ""
    else
        echo "✗ Failed to generate SSH key pair"
        exit 1
    fi
fi

# Check if public key exists
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
    echo "This should not happen if key generation was successful"
    exit 1
fi

# Show key fingerprint
echo "=== Key Fingerprint ==="
ssh-keygen -lf "$PUBLIC_KEY"
echo ""

# Set proper permissions
echo "Setting proper permissions..."
chmod 600 "$PRIVATE_KEY"
chmod 644 "$PUBLIC_KEY"
echo "✓ Permissions set correctly"
echo ""

echo "=== SSH Keys Ready ==="
echo "Your SSH keys are now ready for use!"
echo "Public key content (copy this to your server's authorized_keys):"
echo ""
cat "$PUBLIC_KEY"
echo ""
echo "=== Script completed ===" 