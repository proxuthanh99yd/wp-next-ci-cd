#!/bin/bash

# Simple SSH Keys Display Script
# Get and display id_rsa and id_rsa.pub content

SSH_DIR="$HOME/.ssh"

echo "=== SSH Keys Information ==="
echo "SSH Directory: $SSH_DIR"
echo ""

# Check private key
if [ -f "$SSH_DIR/id_rsa" ]; then
    echo "✓ Private key (id_rsa) found"
    echo "File size: $(ls -lh "$SSH_DIR/id_rsa" | awk '{print $5}')"
    echo "Permissions: $(ls -l "$SSH_DIR/id_rsa" | awk '{print $1}')"
    echo ""
    echo "=== Private Key Content ==="
    cat "$SSH_DIR/id_rsa"
    echo ""
    echo "=== End Private Key ==="
    echo ""
else
    echo "✗ Private key (id_rsa) not found"
    echo ""
fi

# Check public key
if [ -f "$SSH_DIR/id_rsa.pub" ]; then
    echo "✓ Public key (id_rsa.pub) found"
    echo "File size: $(ls -lh "$SSH_DIR/id_rsa.pub" | awk '{print $5}')"
    echo "Permissions: $(ls -l "$SSH_DIR/id_rsa.pub" | awk '{print $1}')"
    echo ""
    echo "=== Public Key Content ==="
    cat "$SSH_DIR/id_rsa.pub"
    echo ""
    echo "=== End Public Key ==="
    echo ""
else
    echo "✗ Public key (id_rsa.pub) not found"
    echo ""
fi

# Show key fingerprint if available
if [ -f "$SSH_DIR/id_rsa.pub" ]; then
    echo "=== Key Fingerprint ==="
    ssh-keygen -lf "$SSH_DIR/id_rsa.pub"
    echo ""
fi

echo "=== Script completed ===" 