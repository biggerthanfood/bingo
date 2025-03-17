#!/usr/bin/env ruby

# Script to set up Flutter and fix CocoaPods framework scripts in Xcode Cloud
# This script runs after the repository is cloned in Xcode Cloud

require 'fileutils'
require 'open-uri'
require 'json'

# Set Flutter version - using 3.7.10+ as recommended for Xcode compatibility
FLUTTER_VERSION = "3.7.10"
FLUTTER_CHANNEL = "stable"

# Define the path where Flutter will be installed
FLUTTER_HOME = File.join(ENV["CI_WORKSPACE"] || Dir.pwd, "flutter")

def download_and_install_flutter
  puts "🔄 Installing Flutter SDK version #{FLUTTER_VERSION} (#{FLUTTER_CHANNEL} channel)..."
  
  # Create directory for Flutter
  FileUtils.mkdir_p(FLUTTER_HOME)
  
  # Download Flutter SDK based on platform
  if RUBY_PLATFORM.include?("darwin")
    # macOS
    puts "📦 Downloading Flutter SDK for macOS..."
    # Clone the repository and checkout the specific version
    system("git clone -b #{FLUTTER_CHANNEL} https://github.com/flutter/flutter.git #{FLUTTER_HOME}") or raise "Failed to download Flutter"
    
    # Move into Flutter directory and checkout the specific version
    Dir.chdir(FLUTTER_HOME) do
      system("git fetch --tags") or raise "Failed to fetch Flutter tags"
      system("git checkout #{FLUTTER_VERSION}") or raise "Failed to checkout Flutter version #{FLUTTER_VERSION}"
    end
  else
    raise "Unsupported platform for Flutter installation: #{RUBY_PLATFORM}"
  end
  
  # Add Flutter to PATH
  ENV["PATH"] = "#{FLUTTER_HOME}/bin:#{ENV["PATH"]}"
  
  # Disable analytics and set up Flutter
  system("flutter config --no-analytics") or raise "Failed to configure Flutter"
  system("flutter precache --ios") or raise "Failed to precache Flutter iOS artifacts"
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
    
    # Fix the symlink resolution more aggressively
    content.gsub!(/source=\$\{source\}/, 'source="${source:-}"')
    content.gsub!(/source="\$\(readlink "\${source\}"(\)|)"/, 'source="$(readlink -f "${source:-}" 2>/dev/null || echo "${source:-}")"')
    content.gsub!(/binary="\$\{dirname\}\/\$\(readlink "\${binary\}"(\)|)"/, 'binary="${dirname}/$(readlink -f "${binary}" 2>/dev/null || echo "${binary}")"')
    
    # Additional fix for readlink without -f flag
    content.gsub!(/readlink ([^-])/, 'readlink -f \\1')
    
    # Write the modified content back to the file
    File.write(script_path, content)
    
    # Make sure the script is executable
    FileUtils.chmod("+x", script_path)
    
    puts "✅ Fixed: #{script_path}"
  end
  
  puts "✅ All CocoaPods framework scripts have been fixed for Xcode Cloud"
end

def disable_user_script_sandboxing
  puts "🔧 Disabling User Script Sandboxing in Xcode project..."
  
  # Find all .xcodeproj directories
  Dir.glob("*.xcodeproj").each do |project_dir|
    project_pbxproj = File.join(project_dir, "project.pbxproj")
    
    if File.exist?(project_pbxproj)
      puts "Found Xcode project: #{project_dir}"
      
      # Read the project file
      content = File.read(project_pbxproj)
      
      # Backup the original file
      FileUtils.cp(project_pbxproj, "#{project_pbxproj}.backup")
      
      # Add USER_SCRIPT_SANDBOXING = NO to all build configurations
      if content.include?("USER_SCRIPT_SANDBOXING")
        # Replace existing setting
        content.gsub!(/USER_SCRIPT_SANDBOXING = YES;/, 'USER_SCRIPT_SANDBOXING = NO;')
      else
        # Add the setting to each build configuration
        content.gsub!(/(buildSettings = \{)/, "\\1\n\t\t\t\tUSER_SCRIPT_SANDBOXING = NO;")
      end
      
      # Write the modified content back to the file
      File.write(project_pbxproj, content)
      
      puts "✅ Disabled User Script Sandboxing in #{project_dir}"
    end
  end
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
        
        # Disable User Script Sandboxing
        disable_user_script_sandboxing
        
        # Run CocoaPods installation with verbose output
        puts "📦 Installing CocoaPods dependencies..."
        system("pod install --verbose") or raise "Failed to install pods"
        
        # Fix the frameworks scripts
        fix_frameworks_scripts
        
        # Verify if the frameworks script is executable
        Dir.glob("Pods/Target Support Files/Pods-*/Pods-*-frameworks.sh").each do |script_path|
          FileUtils.chmod("+x", script_path)
          puts "✅ Verified executable permissions: #{script_path}"
        end
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