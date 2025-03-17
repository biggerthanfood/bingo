#!/bin/sh

# Find all framework scripts in the Pods directory
find "${PODS_ROOT}/Target Support Files" -name "*-frameworks.sh" | while read -r framework_script; do
    echo "Patching script: $framework_script"
    
    # Create a backup
    cp "$framework_script" "${framework_script}.backup"
    
    # Replace the problematic lines
    sed -i '' 's/source=\${source}/source="${source:-}"/g' "$framework_script"
    sed -i '' 's/binary=\${dirname}\/\$(readlink "\${binary}")/binary="${dirname}\/$(readlink "${binary}" || echo "${binary}")"/g' "$framework_script"
    
    # Make sure the script is executable
    chmod +x "$framework_script"
done

# Always exit successfully
exit 0 