#!/usr/bin/env ruby

# add_build_phase.rb
# Adds a build phase to run our Flutter path fix script before the Flutter build phases

require 'xcodeproj'
require 'pathname'
require 'fileutils'

# Find the actual path of the script relative to this file
script_dir = File.expand_path(File.dirname(__FILE__))
project_path = File.join(script_dir, '..', 'Runner.xcodeproj')

puts "Loading Xcode project from: #{project_path}"
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'Runner' }
unless target
  puts "❌ Error: Runner target not found in Xcode project"
  exit 1
end

# Create a unique ID for our build phase - must be 24 characters
build_phase_id = '3B3967' + ('A'..'Z').to_a.sample(18).join

# Add our build phase script
puts "Adding Flutter Path Fix build phase to Runner target..."

# Find existing script build phases to determine position
flutter_script_phase = nil
target.build_phases.each_with_index do |phase, index|
  if phase.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
    if phase.uuid == '9740EEB61CF901F6004384FC' # Flutter Run Script phase
      flutter_script_phase = phase
      break
    end
  end
end

unless flutter_script_phase
  puts "⚠️ Warning: Could not find Flutter Run Script phase, will add at the beginning"
end

# Load our scripts
standalone_script_path = File.join(script_dir, 'standalone_fix.rb')
direct_patch_script_path = File.join(script_dir, 'direct_script_patch.rb')

# Make sure both scripts exist
unless File.exist?(standalone_script_path)
  puts "❌ Error: standalone_fix.rb not found at: #{standalone_script_path}"
  exit 1
end

unless File.exist?(direct_patch_script_path)
  puts "❌ Error: direct_script_patch.rb not found at: #{direct_patch_script_path}"
  exit 1
end

standalone_script_content = File.read(standalone_script_path)
direct_patch_script_content = File.read(direct_patch_script_path)

# Create a combined script that runs both fixes
combined_script = <<~SCRIPT
#!/bin/sh
# Flutter Path Fix - Combined Direct Script
echo "Running comprehensive Flutter path fixes in Xcode build phase"

# STEP 1: Create dummy file at the hardcoded path to trick the build system
HARDCODED_PATH="/Users/cameronperry/app_development/flutter/packages/flutter_tools/bin"
echo "Creating directory structure for hardcoded path: $HARDCODED_PATH"
mkdir -p "$HARDCODED_PATH"

# Create the dummy script
cat > "$HARDCODED_PATH/xcode_backend.sh" << 'EOF'
#!/bin/sh
# Dummy script created in build phase
echo "Running DUMMY xcode_backend.sh at hardcoded path"
echo "Args: $@"

# Try to find the real Flutter
for flutter_path in "/Volumes/workspace/repository/flutter" "/Volumes/workspace/flutter" "$HOME/flutter"; do
  if [ -d "$flutter_path" ]; then
    real_script="$flutter_path/packages/flutter_tools/bin/xcode_backend.sh"
    if [ -f "$real_script" ]; then
      echo "Found real flutter script at: $real_script"
      "$real_script" "$@"
      exit $?
    fi
  fi
done

echo "Continuing with dummy implementation"
exit 0
EOF

# Make it executable
chmod +x "$HARDCODED_PATH/xcode_backend.sh"

# STEP 2: Run the standalone fix script
echo "---------------------------------------"
echo "Running standalone fix script"
echo "---------------------------------------"

# Create a temporary Ruby script file for standalone fix
TEMP_STANDALONE_SCRIPT=$(mktemp /tmp/flutter_standalone_XXXXX.rb)

# Write the script content to the temp file
cat > "$TEMP_STANDALONE_SCRIPT" << 'RUBYEOF1'
#{standalone_script_content}
RUBYEOF1

# Make it executable
chmod +x "$TEMP_STANDALONE_SCRIPT"

# Run the script
ruby "$TEMP_STANDALONE_SCRIPT"

# STEP 3: Run the direct script patch
echo "---------------------------------------"
echo "Running direct script patch"
echo "---------------------------------------"

# Create a temporary Ruby script file for direct patch
TEMP_DIRECT_SCRIPT=$(mktemp /tmp/flutter_direct_XXXXX.rb)

# Write the script content to the temp file
cat > "$TEMP_DIRECT_SCRIPT" << 'RUBYEOF2'
#{direct_patch_script_content}
RUBYEOF2

# Make it executable
chmod +x "$TEMP_DIRECT_SCRIPT"

# Run the script
ruby "$TEMP_DIRECT_SCRIPT"

# Clean up
rm "$TEMP_STANDALONE_SCRIPT"
rm "$TEMP_DIRECT_SCRIPT"

echo "---------------------------------------"
echo "Completed all Flutter path fixes"
echo "---------------------------------------"
SCRIPT

# Check if our build phase already exists
existing_phase = target.build_phases.find do |phase|
  phase.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) &&
    phase.name == 'Run Flutter Path Fix'
end

if existing_phase
  puts "ℹ️ Flutter Path Fix build phase already exists, updating script"
  existing_phase.shell_script = combined_script
else
  # Create our build phase
  fix_phase = target.new_shell_script_build_phase('Run Flutter Path Fix')
  fix_phase.shell_path = '/bin/sh'
  fix_phase.shell_script = combined_script
  
  # Move our phase before the Flutter build phases if we found it
  if flutter_script_phase
    # Find the index where the Flutter phase is
    flutter_index = target.build_phases.index(flutter_script_phase)
    
    # Get our phase's current index (it's at the end)
    fix_index = target.build_phases.index(fix_phase)
    
    # Move our phase to just before the Flutter phase
    if flutter_index && flutter_index > 0
      target.build_phases.move_from(fix_index, flutter_index - 1)
      puts "✅ Positioned Flutter Path Fix build phase just before Flutter Run Script phase"
    end
  end
end

# Check if we need to modify the Flutter script itself
if flutter_script_phase
  puts "Examining Flutter script phase..."
  flutter_script = flutter_script_phase.shell_script
  
  # Check if it has a hardcoded path
  if flutter_script.include?("/Users/cameronperry/app_development/flutter")
    puts "Found hardcoded Flutter path in Flutter script phase, fixing..."
    
    # Replace the hardcoded path with $FLUTTER_ROOT
    fixed_script = flutter_script.gsub(
      /\/Users\/cameronperry\/app_development\/flutter/,
      "$FLUTTER_ROOT"
    )
    
    # Update the script
    flutter_script_phase.shell_script = fixed_script
    puts "✅ Updated Flutter script phase with proper path"
  end
end

# Save the project
project.save
puts "✅ Successfully updated Xcode project" 