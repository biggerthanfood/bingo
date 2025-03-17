#!/usr/bin/env ruby

# encode_firebase_config.rb
# Encodes the GoogleService-Info.plist as base64 to be used in CI environment variables

require 'base64'

# Define the path to the Firebase configuration file
firebase_config_path = File.join(File.dirname(__FILE__), '..', 'Runner', 'GoogleService-Info.plist')

# Check if the file exists
unless File.exist?(firebase_config_path)
  puts "❌ Firebase configuration file not found at: #{firebase_config_path}"
  exit 1
end

# Read the file content
content = File.read(firebase_config_path)

# Encode the content as base64
encoded = Base64.strict_encode64(content)

puts "✅ Firebase configuration file encoded successfully"
puts "📋 Add the following as a CI environment variable named FIREBASE_CONFIG_BASE64:"
puts "\n#{encoded}\n"
puts "🔒 Note: This is sensitive information, do not share it publicly" 