#!/bin/bash

# Test SSH Connection Script
# Test SSH connection to a server

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== SSH Connection Test ===${NC}"
echo ""

# Check if SSH keys exist
SSH_DIR="$HOME/.ssh"
PRIVATE_KEY="$SSH_DIR/id_rsa"

if [ ! -f "$PRIVATE_KEY" ]; then
    echo -e "${RED}✗ SSH private key not found${NC}"
    echo "Generate SSH keys first:"
    echo "  ./get-ssh-keys.sh --generate"
    exit 1
fi

# Get connection details
if [ $# -eq 0 ]; then
    echo "Usage: $0 <user@host> [port]"
    echo ""
    echo "Examples:"
    echo "  $0 user@192.168.1.100"
    echo "  $0 ubuntu@example.com 2222"
    echo ""
    exit 1
fi

HOST="$1"
PORT="${2:-22}"

echo -e "${BLUE}Testing SSH connection to:${NC}"
echo "  Host: $HOST"
echo "  Port: $PORT"
echo ""

# Test basic connectivity
echo -e "${BLUE}1. Testing basic connectivity...${NC}"
if ping -c 1 "$(echo $HOST | cut -d@ -f2)" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Host is reachable${NC}"
else
    echo -e "${RED}✗ Host is not reachable${NC}"
    echo "Check your network connection and host address"
    exit 1
fi
echo ""

# Test SSH port
echo -e "${BLUE}2. Testing SSH port...${NC}"
if timeout 5 bash -c "</dev/tcp/$(echo $HOST | cut -d@ -f2)/$PORT" 2>/dev/null; then
    echo -e "${GREEN}✓ SSH port $PORT is open${NC}"
else
    echo -e "${RED}✗ SSH port $PORT is not accessible${NC}"
    echo "Check if SSH service is running on the server"
    exit 1
fi
echo ""

# Test SSH connection with verbose output
echo -e "${BLUE}3. Testing SSH connection...${NC}"
echo "Attempting to connect (this may take a few seconds)..."
echo ""

# Use ssh with verbose output and timeout
if timeout 30 ssh -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no -p "$PORT" "$HOST" "echo 'SSH connection successful'" 2>&1; then
    echo ""
    echo -e "${GREEN}✓ SSH connection successful!${NC}"
    echo ""
    
    # Test additional SSH features
    echo -e "${BLUE}4. Testing additional SSH features...${NC}"
    
    # Test file transfer capability
    if timeout 10 ssh -o ConnectTimeout=5 -o BatchMode=yes -p "$PORT" "$HOST" "mkdir -p /tmp/ssh-test && echo 'test' > /tmp/ssh-test/test.txt" 2>/dev/null; then
        echo -e "${GREEN}✓ File operations work${NC}"
    else
        echo -e "${YELLOW}⚠ File operations test failed${NC}"
    fi
    
    # Test command execution
    if timeout 10 ssh -o ConnectTimeout=5 -o BatchMode=yes -p "$PORT" "$HOST" "whoami && hostname" 2>/dev/null; then
        echo -e "${GREEN}✓ Command execution works${NC}"
    else
        echo -e "${YELLOW}⚠ Command execution test failed${NC}"
    fi
    
    # Clean up test files
    ssh -o ConnectTimeout=5 -o BatchMode=yes -p "$PORT" "$HOST" "rm -rf /tmp/ssh-test" 2>/dev/null
    
else
    echo ""
    echo -e "${RED}✗ SSH connection failed${NC}"
    echo ""
    echo -e "${YELLOW}Troubleshooting tips:${NC}"
    echo "1. Check if your public key is in server's ~/.ssh/authorized_keys"
    echo "2. Verify SSH service is running on the server"
    echo "3. Check firewall settings"
    echo "4. Ensure correct username and hostname"
    echo "5. Try with verbose output: ssh -v -p $PORT $HOST"
    echo ""
    exit 1
fi

echo ""
echo -e "${GREEN}=== SSH Connection Test Completed Successfully ===${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "• Your SSH connection is working properly"
echo "• You can now use SSH for remote access"
echo "• Consider setting up SSH config for easier access"
echo "• Test file transfer: scp -P $PORT file.txt $HOST:/path/"
echo "" 