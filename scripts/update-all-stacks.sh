#!/bin/bash

# Script that runs dockdate in all folders in a directory

# Check if an argument was provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 [-D | /path/to/folder]"
    echo "  -D              Use current directory as root"
    echo "  /path/to/folder Use specified path as root"
    exit 1
fi

# Determine the root folder
if [ "$1" = "-D" ]; then
    ROOT_DIR="$(pwd)"
else
    ROOT_DIR="$1"
fi

# Verify the root directory exists
if [ ! -d "$ROOT_DIR" ]; then
    echo "Error: Directory '$ROOT_DIR' does not exist"
    exit 1
fi

echo "Using root directory: $ROOT_DIR"

# Save the original directory
ORIGINAL_DIR="$(pwd)"

# Change to root directory
cd "$ROOT_DIR" || exit 1

# Iterate over all folders in the root directory
for dir in */; do
    # Remove trailing slash
    dir="${dir%/}"
    
    if [ -d "$dir" ]; then
        echo "Processing: $dir"
        cd "$dir" || continue
        
        # Run docker compose pull and up -d
        docker compose pull && docker compose up -d
        
        # Return to root directory
        cd "$ROOT_DIR" || exit 1
    fi
done

# Return to original directory
cd "$ORIGINAL_DIR" || exit 1

echo "Done!"