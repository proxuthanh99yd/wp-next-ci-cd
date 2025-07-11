#!/bin/bash

# Helper script to run individual setup modules
# Usage: ./run-module.sh [module_name]

# Available modules
MODULES=(
    "env"
    "docker"
    "system" 
    "ssl"
    "wordpress"
    "plugins"
    "backup"
    "nginx-wordpress"
    "nextjs"
    "nginx-nextjs"
    "verification"
)

# Function to show usage
show_usage() {
    echo "Usage: $0 [module_name]"
    echo ""
    echo "Available modules:"
    for module in "${MODULES[@]}"; do
        echo "  - $module"
    done
    echo ""
    echo "Examples:"
    echo "  $0 env          # Run environment setup"
    echo "  $0 wordpress    # Run WordPress setup"
    echo "  $0 all          # Run all modules in order"
}

# Function to run a specific module
run_module() {
    local module=$1
    local script_file="setup-$module.sh"
    
    if [ ! -f "$script_file" ]; then
        echo "❌ Module script not found: $script_file"
        exit 1
    fi
    
    echo "🚀 Running module: $module"
    echo "📄 Script: $script_file"
    echo "----------------------------------------"
    
    # Make script executable and run it
    chmod +x "$script_file"
    source "$script_file"
    
    echo "----------------------------------------"
    echo "✅ Module $module completed"
}

# Function to run all modules
run_all_modules() {
    echo "🚀 Running all modules in order..."
    echo ""
    
    for module in "${MODULES[@]}"; do
        echo "📦 Running module: $module"
        run_module "$module"
        echo ""
    done
    
    echo "🎉 All modules completed successfully!"
}

# Check if module name is provided
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

# Get module name from argument
MODULE_NAME=$1

# Check if it's "all"
if [ "$MODULE_NAME" = "all" ]; then
    run_all_modules
    exit 0
fi

# Check if module exists
MODULE_FOUND=false
for module in "${MODULES[@]}"; do
    if [ "$module" = "$MODULE_NAME" ]; then
        MODULE_FOUND=true
        break
    fi
done

if [ "$MODULE_FOUND" = false ]; then
    echo "❌ Unknown module: $MODULE_NAME"
    echo ""
    show_usage
    exit 1
fi

# Run the specified module
run_module "$MODULE_NAME" 