#!/usr/bin/env ruby

# Script to set up Flutter and fix CocoaPods framework scripts in Xcode Cloud
# This script runs after the repository is cloned in Xcode Cloud

require 'fileutils'
require 'open-uri'
require 'json'

# Set Flutter version - you can adjust this as needed
FLUTTER_VERSION = "stable"
FLUTTER_CHANNEL = "stable"

# Define the path where Flutter will be installed
FLUTTER_HOME = File.join(ENV["CI_WORKSPACE"] || Dir.pwd, "flutter")

def download_and_install_flutter
  puts "🔄 Installing Flutter SDK (#{FLUTTER_CHANNEL} channel)..."
  
  # Create directory for Flutter
  FileUtils.mkdir_p(FLUTTER_HOME)
  
  # Download Flutter SDK based on platform
  if RUBY_PLATFORM.include?("darwin")
    # macOS
    puts "📦 Downloading Flutter SDK for macOS..."
    system("git clone -b #{FLUTTER_CHANNEL} https://github.com/flutter/flutter.git #{FLUTTER_HOME}") or raise "Failed to download Flutter"
  else
    raise "Unsupported platform for Flutter installation: #{RUBY_PLATFORM}"
  end
  
  # Add Flutter to PATH
  ENV["PATH"] = "#{FLUTTER_HOME}/bin:#{ENV["PATH"]}"
  
  # Disable analytics and set up Flutter
  system("flutter config --no-analytics") or raise "Failed to configure Flutter"
  system("flutter precache") or raise "Failed to precache Flutter"
  system("flutter doctor -v") or raise "Flutter doctor check failed"
  
  puts "✅ Flutter installed successfully at #{FLUTTER_HOME}"
end

def setup_flutter_environment
  puts "🔧 Setting up Flutter environment variables..."
  
  # Set Flutter environment variables
  ENV["FLUTTER_ROOT"] = FLUTTER_HOME
  
  # Get the full path to the project directory
  project_path = ENV["CI_WORKSPACE"] || Dir.pwd
  ENV["FLUTTER_APPLICATION_PATH"] = project_path
  
  # Create or update the Generated.xcconfig file
  flutter_config_dir = File.join(project_path, "ios", "Flutter")
  FileUtils.mkdir_p(flutter_config_dir)
  
  generated_xcconfig = File.join(flutter_config_dir, "Generated.xcconfig")
  File.open(generated_xcconfig, "w") do |file|
    file.puts "// This is a generated file; do not edit or check into version control."
    file.puts "FLUTTER_ROOT=#{FLUTTER_HOME}"
    file.puts "FLUTTER_APPLICATION_PATH=#{project_path}"
    file.puts "COCOAPODS_PARALLEL_CODE_SIGN=true"
    file.puts "FLUTTER_TARGET=lib/main.dart"
    file.puts "FLUTTER_BUILD_DIR=build"
    file.puts "FLUTTER_BUILD_NAME=1.0.0"
    file.puts "FLUTTER_BUILD_NUMBER=1"
    file.puts "EXCLUDED_ARCHS[sdk=iphonesimulator*]=i386"
    file.puts "EXCLUDED_ARCHS[sdk=iphoneos*]=armv7"
    file.puts "DART_OBFUSCATION=false"
    file.puts "TRACK_WIDGET_CREATION=true"
    file.puts "TREE_SHAKE_ICONS=false"
    file.puts "PACKAGE_CONFIG=.dart_tool/package_config.json"
  end
  
  puts "✅ Flutter environment set up successfully"
end

def fix_frameworks_scripts
  puts "🔨 Fixing CocoaPods framework scripts for Xcode Cloud..."
  
  # Find all framework scripts in the Pods directory
  Dir.glob("Pods/Target Support Files/Pods-*/Pods-*-frameworks.sh").each do |script_path|
    puts "Processing: #{script_path}"
    
    # Read the content of the script
    content = File.read(script_path)
    
    # Backup the original file
    FileUtils.cp(script_path, "#{script_path}.backup")
    
    # Fix the symlink resolution
    content.gsub!(/source=\$\{source\}/, 'source="${source:-}"')
    content.gsub!(/source="\$\(readlink "\${source\}"(\)|)"/, 'source="$(readlink -f "${source:-}" || echo "${source:-}")"')
    content.gsub!(/binary="\$\{dirname\}\/\$\(readlink "\${binary\}"(\)|)"/, 'binary="${dirname}/$(readlink -f "${binary}" || echo "${binary}")"')
    
    # Write the modified content back to the file
    File.write(script_path, content)
    
    # Make sure the script is executable
    FileUtils.chmod("+x", script_path)
    
    puts "✅ Fixed: #{script_path}"
  end
  
  puts "✅ All CocoaPods framework scripts have been fixed for Xcode Cloud"
end

begin
  # Navigate to the project directory
  Dir.chdir(ENV["CI_WORKSPACE"] || Dir.pwd) do
    puts "📂 Current directory: #{Dir.pwd}"
    puts "🔍 CI Environment: #{ENV["CI"] ? "Yes" : "No"}"
    puts "🔍 CI Workspace: #{ENV["CI_WORKSPACE"] || "Not set"}"
    
    # Install Flutter
    download_and_install_flutter
    
    # Set up Flutter environment
    setup_flutter_environment
    
    # Run Flutter pub get
    puts "📦 Running flutter pub get..."
    system("flutter pub get") or raise "Failed to run flutter pub get"
    
    # Navigate to the iOS directory
    if Dir.exist?("ios")
      Dir.chdir("ios") do
        puts "📂 Changed to iOS directory: #{Dir.pwd}"
        
        # Run CocoaPods installation
        puts "📦 Installing CocoaPods dependencies..."
        system("pod install") or raise "Failed to install pods"
        
        # Fix the frameworks scripts
        fix_frameworks_scripts
      end
    else
      puts "❌ iOS directory not found"
      exit 1
    end
  end

  puts "🎉 Post-clone script completed successfully"
  exit 0
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace
  exit 1
end 