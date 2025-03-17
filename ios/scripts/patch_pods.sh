#!/bin/sh

FRAMEWORKS_SCRIPT="Pods/Target Support Files/Pods-Runner/Pods-Runner-frameworks.sh"

if [ -f "$FRAMEWORKS_SCRIPT" ]; then
    echo "Patching $FRAMEWORKS_SCRIPT for Xcode Cloud compatibility..."
    
    # Create a backup
    cp "$FRAMEWORKS_SCRIPT" "${FRAMEWORKS_SCRIPT}.backup"
    
    # Replace readlink commands with readlink -f
    sed -i '' 's/source="$(readlink "${source}")"/source="$(readlink -f "${source}" || echo "${source}")"/g' "$FRAMEWORKS_SCRIPT"
    sed -i '' 's/binary="${dirname}\/$(readlink "${binary}")"/binary="${dirname}\/$(readlink -f "${binary}" || echo "${binary}")"/g' "$FRAMEWORKS_SCRIPT"
    
    # Make the script executable
    chmod +x "$FRAMEWORKS_SCRIPT"
    
    echo "Patching complete"
else
    echo "Error: $FRAMEWORKS_SCRIPT not found"
    exit 1
fi 