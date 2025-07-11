#!/bin/bash

# Check SSH Keys Script
# Comprehensive SSH keys status check

SSH_DIR="$HOME/.ssh"
PRIVATE_KEY="$SSH_DIR/id_rsa"
PUBLIC_KEY="$SSH_DIR/id_rsa.pub"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== SSH Keys Status Check ===${NC}"
echo ""

# Check SSH directory
echo -e "${BLUE}1. SSH Directory Check${NC}"
if [ -d "$SSH_DIR" ]; then
    echo -e "${GREEN}✓ SSH directory exists: $SSH_DIR${NC}"
    echo "  Permissions: $(ls -ld "$SSH_DIR" | awk '{print $1}')"
    echo "  Owner: $(ls -ld "$SSH_DIR" | awk '{print $3}')"
    echo "  Group: $(ls -ld "$SSH_DIR" | awk '{print $4}')"
else
    echo -e "${RED}✗ SSH directory not found: $SSH_DIR${NC}"
fi
echo ""

# Check private key
echo -e "${BLUE}2. Private Key Check${NC}"
if [ -f "$PRIVATE_KEY" ]; then
    echo -e "${GREEN}✓ Private key found: $PRIVATE_KEY${NC}"
    echo "  Size: $(ls -lh "$PRIVATE_KEY" | awk '{print $5}')"
    echo "  Permissions: $(ls -l "$PRIVATE_KEY" | awk '{print $1}')"
    echo "  Owner: $(ls -l "$PRIVATE_KEY" | awk '{print $3}')"
    
    # Check if permissions are correct
    if [ "$(stat -c %a "$PRIVATE_KEY")" = "600" ]; then
        echo -e "${GREEN}  ✓ Permissions are correct (600)${NC}"
    else
        echo -e "${YELLOW}  ⚠ Permissions should be 600${NC}"
    fi
else
    echo -e "${RED}✗ Private key not found: $PRIVATE_KEY${NC}"
fi
echo ""

# Check public key
echo -e "${BLUE}3. Public Key Check${NC}"
if [ -f "$PUBLIC_KEY" ]; then
    echo -e "${GREEN}✓ Public key found: $PUBLIC_KEY${NC}"
    echo "  Size: $(ls -lh "$PUBLIC_KEY" | awk '{print $5}')"
    echo "  Permissions: $(ls -l "$PUBLIC_KEY" | awk '{print $1}')"
    echo "  Owner: $(ls -l "$PUBLIC_KEY" | awk '{print $3}')"
    
    # Check if permissions are correct
    if [ "$(stat -c %a "$PUBLIC_KEY")" = "644" ]; then
        echo -e "${GREEN}  ✓ Permissions are correct (644)${NC}"
    else
        echo -e "${YELLOW}  ⚠ Permissions should be 644${NC}"
    fi
    
    # Show key fingerprint
    echo "  Fingerprint: $(ssh-keygen -lf "$PUBLIC_KEY" | awk '{print $2}')"
    echo "  Comment: $(ssh-keygen -lf "$PUBLIC_KEY" | awk '{print $3, $4, $5}')"
else
    echo -e "${RED}✗ Public key not found: $PUBLIC_KEY${NC}"
fi
echo ""

# Check authorized_keys
echo -e "${BLUE}4. Authorized Keys Check${NC}"
if [ -f "$AUTHORIZED_KEYS" ]; then
    echo -e "${GREEN}✓ authorized_keys found: $AUTHORIZED_KEYS${NC}"
    echo "  Size: $(ls -lh "$AUTHORIZED_KEYS" | awk '{print $5}')"
    echo "  Permissions: $(ls -l "$AUTHORIZED_KEYS" | awk '{print $1}')"
    echo "  Owner: $(ls -l "$AUTHORIZED_KEYS" | awk '{print $3}')"
    
    # Check if permissions are correct
    if [ "$(stat -c %a "$AUTHORIZED_KEYS")" = "600" ]; then
        echo -e "${GREEN}  ✓ Permissions are correct (600)${NC}"
    else
        echo -e "${YELLOW}  ⚠ Permissions should be 600${NC}"
    fi
    
    # Count authorized keys
    KEY_COUNT=$(wc -l < "$AUTHORIZED_KEYS" 2>/dev/null || echo "0")
    echo "  Number of authorized keys: $KEY_COUNT"
    
    if [ "$KEY_COUNT" -gt 0 ]; then
        echo "  Keys:"
        while IFS= read -r line; do
            if [ ! -z "$line" ] && [[ ! "$line" =~ ^[[:space:]]*# ]]; then
                echo "    - $(echo "$line" | awk '{print $3}')"
            fi
        done < "$AUTHORIZED_KEYS"
    fi
else
    echo -e "${YELLOW}⚠ authorized_keys not found: $AUTHORIZED_KEYS${NC}"
fi
echo ""

# Check SSH agent
echo -e "${BLUE}5. SSH Agent Check${NC}"
if [ -n "$SSH_AUTH_SOCK" ]; then
    echo -e "${GREEN}✓ SSH agent is running${NC}"
    echo "  Socket: $SSH_AUTH_SOCK"
    
    # Check loaded keys
    if command -v ssh-add >/dev/null 2>&1; then
        LOADED_KEYS=$(ssh-add -l 2>/dev/null | wc -l)
        echo "  Loaded keys: $LOADED_KEYS"
        
        if [ "$LOADED_KEYS" -gt 0 ]; then
            echo "  Key details:"
            ssh-add -l 2>/dev/null | while read -r line; do
                echo "    - $line"
            done
        fi
    fi
else
    echo -e "${YELLOW}⚠ SSH agent is not running${NC}"
    echo "  Start with: eval \$(ssh-agent -s)"
    echo "  Add key: ssh-add ~/.ssh/id_rsa"
fi
echo ""

# Check SSH service (if running as root or with sudo)
echo -e "${BLUE}6. SSH Service Check${NC}"
if command -v systemctl >/dev/null 2>&1; then
    if systemctl is-active --quiet ssh; then
        echo -e "${GREEN}✓ SSH service is running${NC}"
    else
        echo -e "${RED}✗ SSH service is not running${NC}"
    fi
    
    if systemctl is-enabled --quiet ssh; then
        echo -e "${GREEN}✓ SSH service is enabled${NC}"
    else
        echo -e "${YELLOW}⚠ SSH service is not enabled${NC}"
    fi
    
    # Show SSH port
    SSH_PORT=$(ss -tlnp | grep :22 | head -1 | awk '{print $4}' | cut -d: -f2)
    if [ ! -z "$SSH_PORT" ]; then
        echo "  SSH port: $SSH_PORT"
    fi
else
    echo -e "${YELLOW}⚠ systemctl not available${NC}"
fi
echo ""

# Summary
echo -e "${BLUE}=== Summary ===${NC}"
TOTAL_ISSUES=0

if [ ! -d "$SSH_DIR" ]; then
    echo -e "${RED}✗ SSH directory missing${NC}"
    ((TOTAL_ISSUES++))
fi

if [ ! -f "$PRIVATE_KEY" ]; then
    echo -e "${RED}✗ Private key missing${NC}"
    ((TOTAL_ISSUES++))
fi

if [ ! -f "$PUBLIC_KEY" ]; then
    echo -e "${RED}✗ Public key missing${NC}"
    ((TOTAL_ISSUES++))
fi

if [ -z "$SSH_AUTH_SOCK" ]; then
    echo -e "${YELLOW}⚠ SSH agent not running${NC}"
    ((TOTAL_ISSUES++))
fi

if [ $TOTAL_ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓ All SSH components are properly configured${NC}"
else
    echo -e "${YELLOW}⚠ Found $TOTAL_ISSUES issue(s) to address${NC}"
fi
echo ""

# Recommendations
echo -e "${BLUE}=== Recommendations ===${NC}"
if [ ! -d "$SSH_DIR" ] || [ ! -f "$PRIVATE_KEY" ]; then
    echo "• Generate SSH keys: ./get-ssh-keys.sh --generate"
fi

if [ -z "$SSH_AUTH_SOCK" ]; then
    echo "• Start SSH agent: eval \$(ssh-agent -s)"
    echo "• Add key to agent: ssh-add ~/.ssh/id_rsa"
fi

if [ ! -f "$AUTHORIZED_KEYS" ]; then
    echo "• Setup server: ./setup-ssh-server.sh"
fi

echo "• Check permissions: chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_rsa"
echo "• Test connection: ssh user@server"
echo ""

echo -e "${BLUE}=== Check Completed ===${NC}" 