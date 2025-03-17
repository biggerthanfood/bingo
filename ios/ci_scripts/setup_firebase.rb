#!/usr/bin/env ruby

# setup_firebase.rb
# Setup Firebase configuration for CI builds
# Can use either a local file or a base64-encoded file from an environment variable

require 'base64'
require 'fileutils'

# Define paths
FIREBASE_CONFIG_PATH = File.join('Runner', 'GoogleService-Info.plist')
FIREBASE_CONFIG_FULL_PATH = File.join(File.dirname(__FILE__), '..', FIREBASE_CONFIG_PATH)
ENV_VAR_NAME = 'FIREBASE_CONFIG_BASE64'

puts "📱 Setting up Firebase configuration..."

def setup_from_env_var
  # Check if the environment variable exists
  if ENV[ENV_VAR_NAME] && !ENV[ENV_VAR_NAME].empty?
    puts "🔐 Found Firebase configuration in environment variable"
    begin
      # Decode the base64 string
      decoded_content = Base64.strict_decode64(ENV[ENV_VAR_NAME])
      
      # Create the directory if it doesn't exist
      FileUtils.mkdir_p(File.dirname(FIREBASE_CONFIG_FULL_PATH))
      
      # Write the content to the file
      File.write(FIREBASE_CONFIG_FULL_PATH, decoded_content)
      FileUtils.chmod(0644, FIREBASE_CONFIG_FULL_PATH)
      
      puts "✅ Successfully created Firebase configuration from environment variable"
      return true
    rescue => e
      puts "❌ Error decoding Firebase configuration: #{e.message}"
      return false
    end
  else
    puts "⚠️ No Firebase configuration found in environment variable"
    return false
  end
end

def setup_from_local_file
  # Check if the file exists locally (in the git repo)
  local_path = File.join(ENV['CI_WORKSPACE'] || Dir.pwd, 'ios', FIREBASE_CONFIG_PATH)
  if File.exist?(local_path)
    puts "📄 Found local Firebase configuration file: #{local_path}"
    
    # Create the directory if it doesn't exist
    FileUtils.mkdir_p(File.dirname(FIREBASE_CONFIG_FULL_PATH))
    
    # Copy the file to the target location
    FileUtils.cp(local_path, FIREBASE_CONFIG_FULL_PATH)
    FileUtils.chmod(0644, FIREBASE_CONFIG_FULL_PATH)
    
    puts "✅ Successfully copied local Firebase configuration"
    return true
  else
    puts "⚠️ No local Firebase configuration file found at: #{local_path}"
    return false
  end
end

def create_placeholder
  puts "⚠️ Creating placeholder Firebase configuration..."
  
  # Create the directory if it doesn't exist
  FileUtils.mkdir_p(File.dirname(FIREBASE_CONFIG_FULL_PATH))
  
  # Create a placeholder plist file that won't cause build errors
  File.open(FIREBASE_CONFIG_FULL_PATH, 'w') do |file|
    file.puts '<?xml version="1.0" encoding="UTF-8"?>'
    file.puts '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
    file.puts '<plist version="1.0">'
    file.puts '<dict>'
    file.puts '  <key>CLIENT_ID</key>'
    file.puts '  <string>placeholder-client-id</string>'
    file.puts '  <key>REVERSED_CLIENT_ID</key>'
    file.puts '  <string>placeholder.reversed.client.id</string>'
    file.puts '  <key>API_KEY</key>'
    file.puts '  <string>placeholder-api-key</string>'
    file.puts '  <key>GCM_SENDER_ID</key>'
    file.puts '  <string>placeholder-gcm-sender-id</string>'
    file.puts '  <key>PLIST_VERSION</key>'
    file.puts '  <string>1</string>'
    file.puts '  <key>BUNDLE_ID</key>'
    file.puts '  <string>com.example.placeholder</string>'
    file.puts '  <key>PROJECT_ID</key>'
    file.puts '  <string>placeholder-project-id</string>'
    file.puts '  <key>STORAGE_BUCKET</key>'
    file.puts '  <string>placeholder-storage-bucket</string>'
    file.puts '  <key>IS_ADS_ENABLED</key>'
    file.puts '  <false/>'
    file.puts '  <key>IS_ANALYTICS_ENABLED</key>'
    file.puts '  <false/>'
    file.puts '  <key>IS_APPINVITE_ENABLED</key>'
    file.puts '  <false/>'
    file.puts '  <key>IS_GCM_ENABLED</key>'
    file.puts '  <false/>'
    file.puts '  <key>IS_SIGNIN_ENABLED</key>'
    file.puts '  <false/>'
    file.puts '  <key>GOOGLE_APP_ID</key>'
    file.puts '  <string>placeholder-app-id</string>'
    file.puts '</dict>'
    file.puts '</plist>'
  end
  
  FileUtils.chmod(0644, FIREBASE_CONFIG_FULL_PATH)
  puts "✅ Created placeholder Firebase configuration"
  return true
end

# Try to set up Firebase configuration in order of preference
success = setup_from_env_var || setup_from_local_file || create_placeholder

# Check if the file is correctly set up now
if File.exist?(FIREBASE_CONFIG_FULL_PATH)
  puts "🔍 Firebase configuration file exists at: #{FIREBASE_CONFIG_FULL_PATH}"
  puts "📄 Firebase configuration file size: #{File.size(FIREBASE_CONFIG_FULL_PATH)} bytes"
else
  puts "❌ Failed to create Firebase configuration file"
  exit 1
end

puts "✅ Firebase configuration setup complete" 