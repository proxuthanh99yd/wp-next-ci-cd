#!/bin/bash

# Install WordPress plugins in specific order
echo -e "\n🔧 Installing WordPress plugins..."

# Install plugins from wp-plugin folder in specific order
if [ -d "wp-plugin" ]; then
    # Define plugin installation order
    declare -a plugins=(
        "all-in-one-wp-migration"
        "all-in-one-wp-migration-unlimited-extension"
    )
    
    for plugin_name in "${plugins[@]}"; do
        plugin_file="wp-plugin/${plugin_name}.zip"
        if [ -f "$plugin_file" ]; then
            echo -e "\n📦 Installing $plugin_name..."
            
            # Copy plugin to WordPress container
            docker cp "$plugin_file" wordpress:/tmp/
            
            # Install plugin using WP-CLI
            if docker exec wordpress wp plugin install /tmp/"$(basename "$plugin_file")" --activate --allow-root; then
                echo "✅ $plugin_name installed and activated successfully"
                
                # Wait a moment for plugin to fully activate
                sleep 5
            else
                echo "❌ Failed to install $plugin_name"
            fi
            
            # Clean up temporary file
            docker exec wordpress rm -f /tmp/"$(basename "$plugin_file")"
        else
            echo "⚠️  Plugin file not found: $plugin_file"
        fi
    done
    
    # Install any other plugins that might be in the folder
    for plugin_file in wp-plugin/*.zip; do
        if [ -f "$plugin_file" ]; then
            plugin_name=$(basename "$plugin_file" .zip)
            
            # Skip if already installed in order
            if [[ " ${plugins[@]} " =~ " ${plugin_name} " ]]; then
                continue
            fi
            
            echo -e "\n📦 Installing additional plugin: $plugin_name..."
            
            # Copy plugin to WordPress container
            docker cp "$plugin_file" wordpress:/tmp/
            
            # Install plugin using WP-CLI
            if docker exec wordpress wp plugin install /tmp/"$(basename "$plugin_file")" --activate --allow-root; then
                echo "✅ $plugin_name installed and activated successfully"
            else
                echo "❌ Failed to install $plugin_name"
            fi
            
            # Clean up temporary file
            docker exec wordpress rm -f /tmp/"$(basename "$plugin_file")"
        fi
    done
else
    echo "⚠️  wp-plugin folder not found"
fi

# Verify WordPress is fully functional after plugin installation
echo -e "\n🔍 Verifying WordPress functionality..."
if ! docker exec wordpress wp core is-installed --allow-root 2>/dev/null; then
    echo -e "\n❌ WordPress verification failed after plugin installation!"
    exit 1
fi

echo -e "\n✅ WordPress is fully ready with plugins installed!"
echo "✅ Plugin setup completed" 