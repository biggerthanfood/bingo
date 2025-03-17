#!/usr/bin/env ruby

# add_firebase_script_phase.rb
# Adds a script build phase to the Xcode project that creates the GoogleService-Info.plist file

require 'xcodeproj'
require 'fileutils'

# Path to the Xcode project file
PROJECT_PATH = File.join(File.dirname(__FILE__), '..', 'Runner.xcodeproj')

# Find the project
project = Xcodeproj::Project.open(PROJECT_PATH)
target = project.targets.find { |t| t.name == 'Runner' }

if target
  puts "🔨 Adding Firebase script build phase to target: #{target.name}"
  
  # Check if the build phase already exists
  firebase_phase = target.shell_script_build_phases.find { |phase| phase.name == 'Generate Firebase Config' }
  
  if firebase_phase
    puts "⚠️ Firebase build phase already exists, updating it..."
    # Remove the existing phase to add a new one with updated script
    target.build_phases.delete(firebase_phase)
  end
  
  # Create a new script build phase right after 'Check Pods Manifest.lock'
  insert_at_index = nil
  target.build_phases.each_with_index do |phase, index|
    if phase.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) && 
       phase.name == 'Check Pods Manifest.lock'
      insert_at_index = index + 1
      break
    end
  end
  
  # If we couldn't find the right spot, add it at the beginning
  insert_at_index ||= 0
  
  # Create the new build phase
  firebase_phase = target.new_shell_script_build_phase
  firebase_phase.name = 'Generate Firebase Config'
  
  # The shell script to generate the GoogleService-Info.plist
  firebase_phase.shell_script = <<~SCRIPT
  #!/bin/sh
  
  # Script to generate GoogleService-Info.plist during build
  
  # Define target path for Firebase config file
  FIREBASE_CONFIG_PATH="${SRCROOT}/Runner/GoogleService-Info.plist"
  
  echo "🔍 Checking for Firebase configuration at: ${FIREBASE_CONFIG_PATH}"
  
  # 1. First try to use the environment variable if it exists
  if [ -n "$FIREBASE_CONFIG_BASE64" ]; then
    echo "🔐 Found Firebase configuration in environment variable, decoding..."
    echo "$FIREBASE_CONFIG_BASE64" | base64 --decode > "${FIREBASE_CONFIG_PATH}"
    if [ $? -eq 0 ]; then
      echo "✅ Successfully created Firebase configuration from environment variable"
      exit 0
    else
      echo "⚠️ Failed to decode Firebase configuration from environment variable"
    fi
  else
    echo "⚠️ No Firebase configuration found in environment variable"
  fi
  
  # 2. Check if file already exists (locally)
  if [ -f "${FIREBASE_CONFIG_PATH}" ]; then
    echo "✅ Firebase configuration file exists locally"
    # Make a copy to ensure it's fresh
    cp "${FIREBASE_CONFIG_PATH}" "${FIREBASE_CONFIG_PATH}.build"
    mv "${FIREBASE_CONFIG_PATH}.build" "${FIREBASE_CONFIG_PATH}"
    exit 0
  fi
  
  # 3. Create a placeholder as last resort
  echo "⚠️ Firebase configuration file not found, creating placeholder..."
  
  # Create a placeholder plist file that won't cause build errors
  cat > "${FIREBASE_CONFIG_PATH}" << 'EOF'
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
    <key>CLIENT_ID</key>
    <string>placeholder-client-id</string>
    <key>REVERSED_CLIENT_ID</key>
    <string>placeholder.reversed.client.id</string>
    <key>API_KEY</key>
    <string>placeholder-api-key</string>
    <key>GCM_SENDER_ID</key>
    <string>placeholder-gcm-sender-id</string>
    <key>PLIST_VERSION</key>
    <string>1</string>
    <key>BUNDLE_ID</key>
    <string>com.example.placeholder</string>
    <key>PROJECT_ID</key>
    <string>placeholder-project-id</string>
    <key>STORAGE_BUCKET</key>
    <string>placeholder-storage-bucket</string>
    <key>IS_ADS_ENABLED</key>
    <false/>
    <key>IS_ANALYTICS_ENABLED</key>
    <false/>
    <key>IS_APPINVITE_ENABLED</key>
    <false/>
    <key>IS_GCM_ENABLED</key>
    <false/>
    <key>IS_SIGNIN_ENABLED</key>
    <false/>
    <key>GOOGLE_APP_ID</key>
    <string>placeholder-app-id</string>
  </dict>
  </plist>
  EOF
  
  echo "✅ Created placeholder Firebase configuration file"
  exit 0
  SCRIPT
  
  # Add input/output files to ensure Xcode knows this script generates the plist
  firebase_phase.input_paths = []
  firebase_phase.output_paths = ["$(SRCROOT)/Runner/GoogleService-Info.plist"]
  
  # Move the build phase to the right position
  target.build_phases.move_from(target.build_phases.count - 1, insert_at_index)
  
  # Save the project
  project.save
  
  puts "✅ Successfully added Firebase script build phase to Xcode project"
else
  puts "❌ Could not find Runner target in Xcode project"
  exit 1
end 