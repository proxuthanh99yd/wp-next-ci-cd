#!/bin/bash

# Function to find backup file in local directory
find_local_backup() {
    # Check wp-content/ai1wm-backups first (WordPress backup directory)
    local backup_dir="wp-content/ai1wm-backups"
    if [ -d "$backup_dir" ]; then
        # Find the most recent .wpress file
        local latest_backup=$(find "$backup_dir" -name "*.wpress" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
        if [ ! -z "$latest_backup" ]; then
            echo "$latest_backup"
            return 0
        fi
    fi
    
    # Fallback to wp-backups directory
    local backup_dir="wp-backups"
    if [ -d "$backup_dir" ]; then
        # Find the most recent .wpress file
        local latest_backup=$(find "$backup_dir" -name "*.wpress" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
        if [ ! -z "$latest_backup" ]; then
            echo "$latest_backup"
            return 0
        fi
    fi
    return 1
}

# Download and restore WordPress backup if URL is provided
if [ ! -z "$WORDPRESS_BACKUP_URL" ] && [ "$WORDPRESS_BACKUP_URL" != "https://example.com/backup.wpress" ]; then
    echo -e "\n📥 Downloading WordPress backup..."
    
    # Create ai1wm-backups directory if it doesn't exist
    docker exec wordpress mkdir -p /var/www/html/wp-content/ai1wm-backups
    
    # Fix permissions for backup directory
    docker exec wordpress chown -R www-data:www-data /var/www/html/wp-content/ai1wm-backups
    docker exec wordpress chmod -R 777 /var/www/html/wp-content/ai1wm-backups
    
    # Get filename from URL (extract the last part of the path)
    backup_filename=$(basename "$WORDPRESS_BACKUP_URL")
    echo "📁 Backup filename: $backup_filename"
    
    # Check if backup file already exists in container
    if docker exec wordpress test -f "/var/www/html/wp-content/ai1wm-backups/$backup_filename"; then
        echo "✅ Backup file already exists: $backup_filename"
    else
        # Download backup file to WordPress container (using curl which is usually available)
        echo "📥 Downloading backup file..."
        if docker exec wordpress curl -L -o "/var/www/html/wp-content/ai1wm-backups/$backup_filename" "$WORDPRESS_BACKUP_URL"; then
            echo "✅ Backup downloaded successfully: $backup_filename"
        else
            echo "❌ Failed to download backup from: $WORDPRESS_BACKUP_URL"
            exit 1
        fi
    fi
    
    # Wait a moment for file to be fully written
    sleep 3
    
    # Verify backup file exists and has content
    if docker exec wordpress test -s "/var/www/html/wp-content/ai1wm-backups/$backup_filename"; then
        echo "✅ Backup file verified: $backup_filename (size > 0)"
    else
        echo "❌ Backup file is empty or not found: $backup_filename"
        exit 1
    fi
    
    # Restore backup using WP-CLI
    echo -e "\n🔄 Restoring WordPress backup..."
    
    # Check if AI1WM plugin is active
    if ! docker exec wordpress wp plugin is-active all-in-one-wp-migration --allow-root 2>/dev/null; then
        echo "❌ AI1WM plugin is not active. Activating..."
        docker exec wordpress wp plugin activate all-in-one-wp-migration --allow-root
    fi
    
    # Check if AI1WM Unlimited Extension is active
    if ! docker exec wordpress wp plugin is-active all-in-one-wp-migration-unlimited-extension --allow-root 2>/dev/null; then
        echo "❌ AI1WM Unlimited Extension is not active. Activating..."
        docker exec wordpress wp plugin activate all-in-one-wp-migration-unlimited-extension --allow-root
    fi
    
    # List backup files for debugging
    echo "📋 Available backup files:"
    docker exec wordpress ls -la /var/www/html/wp-content/ai1wm-backups/
    
    # Try restore with better error handling
    echo "🔄 Attempting restore..."
    echo "⚠️  WordPress will ask for confirmation before restoring..."
    echo "   Backup file: $backup_filename"
    echo ""
    if docker exec -i wordpress wp ai1wm restore "/var/www/html/wp-content/ai1wm-backups/$backup_filename" --allow-root; then
        echo "✅ WordPress backup restored successfully!"
        
        # Wait for restore to complete
        sleep 10
        
        # Fix permissions after restore
        echo "🔧 Fixing permissions after restore..."
        docker exec wordpress chown -R www-data:www-data /var/www/html
        docker exec wordpress chmod -R 755 /var/www/html
        docker exec wordpress chmod -R 777 /var/www/html/wp-content
        
        # Verify WordPress is still functional after restore
        if docker exec wordpress wp core is-installed --allow-root 2>/dev/null; then
            echo "✅ WordPress verification after restore: OK"
        else
            echo "⚠️  WordPress verification after restore: Failed"
        fi
    else
        echo "❌ Failed to restore WordPress backup"
        echo "🔍 Debugging information:"
        echo "   - Backup file: $backup_filename"
        echo "   - File size: $(docker exec wordpress ls -lh /var/www/html/wp-content/ai1wm-backups/$backup_filename 2>/dev/null || echo 'File not found')"
        echo "   - AI1WM plugin status: $(docker exec wordpress wp plugin list --status=active --allow-root | grep ai1wm || echo 'Not found')"
        echo "   - WordPress status: $(docker exec wordpress wp core is-installed --allow-root 2>/dev/null && echo 'Installed' || echo 'Not installed')"
        exit 1
    fi
else
    echo -e "\n⚠️  No backup URL provided or using default URL."
    
    # Try to find local backup file
    echo "🔍 Looking for local backup files..."
    local_backup=$(find_local_backup)
    
    if [ ! -z "$local_backup" ]; then
        echo "📁 Found local backup: $local_backup"
        
        # Create ai1wm-backups directory if it doesn't exist
        docker exec wordpress mkdir -p /var/www/html/wp-content/ai1wm-backups
        
        # Fix permissions for backup directory
        docker exec wordpress chown -R www-data:www-data /var/www/html/wp-content/ai1wm-backups
        docker exec wordpress chmod -R 777 /var/www/html/wp-content/ai1wm-backups
        
        # Get filename from path
        backup_filename=$(basename "$local_backup")
        echo "📁 Backup filename: $backup_filename"
        
        # Copy local backup to container
        echo "📥 Copying local backup to container..."
        if docker cp "$local_backup" wordpress:/var/www/html/wp-content/ai1wm-backups/; then
            echo "✅ Local backup copied successfully: $backup_filename"
            
            # Wait a moment for file to be fully written
            sleep 3
            
            # Verify backup file exists and has content
            if docker exec wordpress test -s "/var/www/html/wp-content/ai1wm-backups/$backup_filename"; then
                echo "✅ Backup file verified: $backup_filename (size > 0)"
                
                # Restore backup using WP-CLI
                echo -e "\n🔄 Restoring WordPress backup..."
                
                # Check if AI1WM plugin is active
                if ! docker exec wordpress wp plugin is-active all-in-one-wp-migration --allow-root 2>/dev/null; then
                    echo "❌ AI1WM plugin is not active. Activating..."
                    docker exec wordpress wp plugin activate all-in-one-wp-migration --allow-root
                fi
                
                # Check if AI1WM Unlimited Extension is active
                if ! docker exec wordpress wp plugin is-active all-in-one-wp-migration-unlimited-extension --allow-root 2>/dev/null; then
                    echo "❌ AI1WM Unlimited Extension is not active. Activating..."
                    docker exec wordpress wp plugin activate all-in-one-wp-migration-unlimited-extension --allow-root
                fi
                
                # List backup files for debugging
                echo "📋 Available backup files:"
                docker exec wordpress ls -la /var/www/html/wp-content/ai1wm-backups/
                
                # Try restore with better error handling
                echo "🔄 Attempting restore..."
                echo "⚠️  WordPress will ask for confirmation before restoring..."
                echo "   Backup file: $backup_filename"
                echo ""
                if docker exec -i wordpress wp ai1wm restore "/var/www/html/wp-content/ai1wm-backups/$backup_filename" --allow-root; then
                    echo "✅ WordPress backup restored successfully!"
                    
                    # Wait for restore to complete
                    sleep 10
                    
                    # Fix permissions after restore
                    echo "🔧 Fixing permissions after restore..."
                    docker exec wordpress chown -R www-data:www-data /var/www/html
                    docker exec wordpress chmod -R 755 /var/www/html
                    docker exec wordpress chmod -R 777 /var/www/html/wp-content
                    
                    # Verify WordPress is still functional after restore
                    if docker exec wordpress wp core is-installed --allow-root 2>/dev/null; then
                        echo "✅ WordPress verification after restore: OK"
                    else
                        echo "⚠️  WordPress verification after restore: Failed"
                    fi
                else
                    echo "❌ Failed to restore WordPress backup"
                    echo "🔍 Debugging information:"
                    echo "   - Backup file: $backup_filename"
                    echo "   - File size: $(docker exec wordpress ls -lh /var/www/html/wp-content/ai1wm-backups/$backup_filename 2>/dev/null || echo 'File not found')"
                    echo "   - AI1WM plugin status: $(docker exec wordpress wp plugin list --status=active --allow-root | grep ai1wm || echo 'Not found')"
                    echo "   - WordPress status: $(docker exec wordpress wp core is-installed --allow-root 2>/dev/null && echo 'Installed' || echo 'Not installed')"
                    exit 1
                fi
            else
                echo "❌ Backup file is empty or not found: $backup_filename"
                exit 1
            fi
        else
            echo "❌ Failed to copy local backup to container"
            exit 1
        fi
    else
        echo "   To restore backup, either:"
        echo "   1. Set WORDPRESS_BACKUP_URL in .env file, or"
        echo "   2. Place .wpress backup file in wp-content/ai1wm-backups/ directory"
    fi
fi

echo "✅ Backup setup completed" 