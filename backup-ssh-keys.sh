#!/bin/bash

# Backup SSH Keys Script
# Create timestamped backup of SSH keys

SSH_DIR="$HOME/.ssh"
PRIVATE_KEY="$SSH_DIR/id_rsa"
PUBLIC_KEY="$SSH_DIR/id_rsa.pub"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== SSH Keys Backup Script ===${NC}"
echo ""

# Check if SSH keys exist
if [ ! -f "$PRIVATE_KEY" ] && [ ! -f "$PUBLIC_KEY" ]; then
    echo -e "${RED}✗ No SSH keys found to backup${NC}"
    echo "Generate SSH keys first using:"
    echo "  ./get-ssh-keys.sh --generate"
    echo "  or"
    echo "  ./ssh-keys-manager.sh"
    exit 1
fi

# Create backup directory with timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$HOME/ssh-backup-$TIMESTAMP"

echo "Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Backup private key
if [ -f "$PRIVATE_KEY" ]; then
    cp "$PRIVATE_KEY" "$BACKUP_DIR/"
    echo -e "${GREEN}✓ Private key backed up${NC}"
    echo "  Source: $PRIVATE_KEY"
    echo "  Destination: $BACKUP_DIR/id_rsa"
    echo "  Size: $(ls -lh "$PRIVATE_KEY" | awk '{print $5}')"
    echo ""
else
    echo -e "${YELLOW}⚠ Private key not found${NC}"
fi

# Backup public key
if [ -f "$PUBLIC_KEY" ]; then
    cp "$PUBLIC_KEY" "$BACKUP_DIR/"
    echo -e "${GREEN}✓ Public key backed up${NC}"
    echo "  Source: $PUBLIC_KEY"
    echo "  Destination: $BACKUP_DIR/id_rsa.pub"
    echo "  Size: $(ls -lh "$PUBLIC_KEY" | awk '{print $5}')"
    echo ""
else
    echo -e "${YELLOW}⚠ Public key not found${NC}"
fi

# Create backup info file
cat > "$BACKUP_DIR/backup-info.txt" << EOF
SSH Keys Backup
===============
Backup Date: $(date)
Backup Time: $(date +%H:%M:%S)
User: $(whoami)
Host: $(hostname)
SSH Directory: $SSH_DIR

Files backed up:
$(ls -la "$BACKUP_DIR" | grep -E "(id_rsa|id_rsa\.pub)")

Restore Instructions:
1. Copy files back to ~/.ssh/
2. Set proper permissions:
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/id_rsa
   chmod 644 ~/.ssh/id_rsa.pub

Security Note:
- Keep this backup secure
- Don't share private key files
- Delete backup after successful restore
EOF

echo -e "${GREEN}✓ Backup info file created${NC}"
echo ""

# Show backup contents
echo -e "${BLUE}=== Backup Contents ===${NC}"
ls -la "$BACKUP_DIR"
echo ""

# Show backup size
BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | awk '{print $1}')
echo -e "${GREEN}✓ Backup completed successfully${NC}"
echo "Backup location: $BACKUP_DIR"
echo "Backup size: $BACKUP_SIZE"
echo ""

# Security warning
echo -e "${YELLOW}⚠ Security Warning ⚠${NC}"
echo "1. Keep this backup secure and private"
echo "2. Don't share the private key file"
echo "3. Delete the backup after successful restore"
echo "4. Consider encrypting the backup directory"
echo ""

echo -e "${BLUE}=== Backup Script Completed ===${NC}" 