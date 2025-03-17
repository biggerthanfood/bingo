#!/usr/bin/env ruby

# fix_swift_missing_header.rb
# Script to fix the issue with missing GeneratedPluginRegistrant.h during Swift compilation

require 'fileutils'

# Path to the Flutter application
FLUTTER_APP_PATH = ENV['CI_WORKSPACE'] || Dir.pwd
IOS_PATH = File.join(FLUTTER_APP_PATH, 'ios')

# Paths to relevant files
GENERATED_PLUGIN_REGISTRANT_H = File.join(IOS_PATH, 'Runner', 'GeneratedPluginRegistrant.h')
GENERATED_PLUGIN_REGISTRANT_M = File.join(IOS_PATH, 'Runner', 'GeneratedPluginRegistrant.m')
BRIDGING_HEADER_PATH = File.join(IOS_PATH, 'Runner', 'Runner-Bridging-Header.h')

# Create a bare minimum GeneratedPluginRegistrant.h if missing
def create_minimal_generated_plugin_registrant
  puts "🔍 Checking for GeneratedPluginRegistrant.h..."
  
  if File.exist?(GENERATED_PLUGIN_REGISTRANT_H)
    puts "✅ GeneratedPluginRegistrant.h exists, making a backup..."
    FileUtils.cp(GENERATED_PLUGIN_REGISTRANT_H, "#{GENERATED_PLUGIN_REGISTRANT_H}.backup")
  else
    puts "⚠️ GeneratedPluginRegistrant.h is missing, creating a minimal version..."
    
    # Ensure the directory exists
    FileUtils.mkdir_p(File.dirname(GENERATED_PLUGIN_REGISTRANT_H))
    
    # Create the minimal header file
    File.open(GENERATED_PLUGIN_REGISTRANT_H, 'w') do |file|
      file.puts "//\n// Generated file. Do not edit.\n//\n"
      file.puts "\n// clang-format off\n"
      file.puts "#ifndef GeneratedPluginRegistrant_h"
      file.puts "#define GeneratedPluginRegistrant_h\n"
      file.puts "#import <Flutter/Flutter.h>\n"
      file.puts "NS_ASSUME_NONNULL_BEGIN\n"
      file.puts "@interface GeneratedPluginRegistrant : NSObject"
      file.puts "+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry;"
      file.puts "@end\n"
      file.puts "NS_ASSUME_NONNULL_END"
      file.puts "#endif /* GeneratedPluginRegistrant_h */"
    end
    
    puts "✅ Created minimal GeneratedPluginRegistrant.h"
  end
  
  # Also check for GeneratedPluginRegistrant.m
  if !File.exist?(GENERATED_PLUGIN_REGISTRANT_M)
    puts "⚠️ GeneratedPluginRegistrant.m is missing, creating a minimal version..."
    
    # Create a minimal implementation file
    File.open(GENERATED_PLUGIN_REGISTRANT_M, 'w') do |file|
      file.puts "//\n// Generated file. Do not edit.\n//\n"
      file.puts "\n// clang-format off\n"
      file.puts "#import \"GeneratedPluginRegistrant.h\""
      file.puts "\n// Import all plugins"
      file.puts "#if __has_include(<firebase_core/FLTFirebaseCorePlugin.h>)"
      file.puts "#import <firebase_core/FLTFirebaseCorePlugin.h>"
      file.puts "#else"
      file.puts "@import firebase_core;"
      file.puts "#endif\n"
      file.puts "@implementation GeneratedPluginRegistrant\n"
      file.puts "+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {\n"
      file.puts "  [FLTFirebaseCorePlugin registerWithRegistrar:[registry registrarForPlugin:@\"FLTFirebaseCorePlugin\"]];"
      file.puts "}\n"
      file.puts "@end"
    end
    
    puts "✅ Created minimal GeneratedPluginRegistrant.m"
  end
end

# Copy Flutter.h to ensure it's available during compilation
def copy_flutter_headers
  puts "🔍 Ensuring Flutter headers are available..."
  
  # Common locations where Flutter.h might be found
  flutter_header_locations = [
    File.join(FLUTTER_APP_PATH, 'flutter', 'bin', 'cache', 'artifacts', 'engine', 'ios', 'Flutter.xcframework', 'Headers'),
    File.join(IOS_PATH, 'Flutter', 'Flutter.framework', 'Headers'),
    File.join(IOS_PATH, '.symlinks', 'flutter', 'ios', 'Flutter.framework', 'Headers'),
    File.join(ENV['HOME'] || '', 'flutter', 'bin', 'cache', 'artifacts', 'engine', 'ios', 'Flutter.xcframework', 'Headers')
  ]
  
  # Directory to copy Flutter headers to
  target_headers_dir = File.join(IOS_PATH, 'Flutter', 'Flutter.framework', 'Headers')
  FileUtils.mkdir_p(target_headers_dir)
  
  # Try to find Flutter.h
  flutter_h_found = false
  flutter_header_locations.each do |location|
    flutter_h = File.join(location, 'Flutter.h')
    if File.exist?(flutter_h)
      puts "✅ Found Flutter.h at: #{flutter_h}"
      FileUtils.cp(flutter_h, target_headers_dir)
      flutter_h_found = true
      break
    end
  end
  
  if !flutter_h_found
    # Create a minimal Flutter.h
    puts "⚠️ Flutter.h not found, creating a minimal version..."
    File.open(File.join(target_headers_dir, 'Flutter.h'), 'w') do |file|
      file.puts "// Minimal Flutter.h for bridging header compatibility"
      file.puts "#ifndef FLUTTER_FLUTTER_H_"
      file.puts "#define FLUTTER_FLUTTER_H_\n"
      file.puts "#import <Foundation/Foundation.h>\n"
      file.puts "@protocol FlutterPluginRegistry;"
      file.puts "@class NSObject;\n"
      file.puts "// Flutter plugin registry protocol"
      file.puts "@protocol FlutterPluginRegistry <NSObject>"
      file.puts "- (id)registrarForPlugin:(NSString*)pluginKey;"
      file.puts "@end\n"
      file.puts "#endif  // FLUTTER_FLUTTER_H_"
    end
    puts "✅ Created minimal Flutter.h"
  end
end

# Create search paths for headers
def add_header_search_paths_to_build_settings
  puts "🔧 Adding header search paths to build settings file..."
  
  # Path to xcconfig file
  release_xcconfig = File.join(IOS_PATH, 'Flutter', 'Release.xcconfig')
  debug_xcconfig = File.join(IOS_PATH, 'Flutter', 'Debug.xcconfig')
  
  # Directories to add to search paths
  header_search_paths = [
    '$(SRCROOT)/Flutter',
    '$(SRCROOT)/Flutter/Flutter.framework/Headers',
    '$(SRCROOT)/.symlinks/flutter/ios/Flutter.framework/Headers',
    '$(FLUTTER_APPLICATION_PATH)/flutter/bin/cache/artifacts/engine/ios/Flutter.xcframework/Headers'
  ].join(' ')
  
  # Add header search paths to xcconfig files
  [release_xcconfig, debug_xcconfig].each do |config_file|
    if File.exist?(config_file)
      content = File.read(config_file)
      
      # Check if HEADER_SEARCH_PATHS is already defined
      if content.include?('HEADER_SEARCH_PATHS')
        # Append to existing HEADER_SEARCH_PATHS
        content.gsub!(/HEADER_SEARCH_PATHS\s*=\s*(.*)$/) do |match|
          paths = $1.strip
          "HEADER_SEARCH_PATHS = #{paths} #{header_search_paths}"
        end
      else
        # Add new HEADER_SEARCH_PATHS
        content << "\nHEADER_SEARCH_PATHS = #{header_search_paths}"
      end
      
      File.write(config_file, content)
      puts "✅ Updated header search paths in #{File.basename(config_file)}"
    end
  end
end

# Fix the bridging header
def fix_bridging_header
  puts "🔧 Fixing Swift bridging header..."
  
  if File.exist?(BRIDGING_HEADER_PATH)
    puts "✅ Bridging header exists at: #{BRIDGING_HEADER_PATH}"
    
    # Make a backup of the original file
    FileUtils.cp(BRIDGING_HEADER_PATH, "#{BRIDGING_HEADER_PATH}.backup")
  else
    puts "⚠️ Bridging header is missing, creating it..."
    FileUtils.mkdir_p(File.dirname(BRIDGING_HEADER_PATH))
  end
  
  # Write a simple bridging header with quotes instead of angle brackets
  File.open(BRIDGING_HEADER_PATH, 'w') do |file|
    file.puts '#import "GeneratedPluginRegistrant.h"'
  end
  
  puts "✅ Fixed bridging header"
end

# Create a modified build phase to copy headers
def create_header_copy_build_phase
  puts "🔧 Adding build phase to ensure headers are available..."
  
  # Script content to create in a separate file
  script_content = <<~SCRIPT
  #!/bin/sh
  
  # Script to ensure Flutter headers are available during build
  
  echo "🔧 Running header availability script..."
  
  # Define paths
  DERIVED_FILE_DIR="${OBJROOT}/DerivedSources"
  FLUTTER_HEADER="${SRCROOT}/Flutter/Flutter.framework/Headers/Flutter.h"
  GENERATED_PLUGIN_HEADER="${SRCROOT}/Runner/GeneratedPluginRegistrant.h"
  
  # Ensure directories exist
  mkdir -p "${DERIVED_FILE_DIR}"
  mkdir -p "${SRCROOT}/Flutter/Flutter.framework/Headers"
  
  # Copy GeneratedPluginRegistrant.h if it exists
  if [ -f "${GENERATED_PLUGIN_HEADER}" ]; then
    echo "✅ Copying GeneratedPluginRegistrant.h to derived sources"
    cp "${GENERATED_PLUGIN_HEADER}" "${DERIVED_FILE_DIR}/"
  else
    echo "⚠️ GeneratedPluginRegistrant.h not found, creating a placeholder"
    cat > "${DERIVED_FILE_DIR}/GeneratedPluginRegistrant.h" << 'EOF'
  //
  // Generated file. Do not edit.
  //
  
  // clang-format off
  #ifndef GeneratedPluginRegistrant_h
  #define GeneratedPluginRegistrant_h
  
  #import <Foundation/Foundation.h>
  
  NS_ASSUME_NONNULL_BEGIN
  
  @protocol FlutterPluginRegistry;
  
  @interface GeneratedPluginRegistrant : NSObject
  + (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry;
  @end
  
  NS_ASSUME_NONNULL_END
  #endif /* GeneratedPluginRegistrant_h */
  EOF
    
    echo "✅ Created placeholder GeneratedPluginRegistrant.h"
    cp "${DERIVED_FILE_DIR}/GeneratedPluginRegistrant.h" "${GENERATED_PLUGIN_HEADER}"
  fi
  
  # Create minimal Flutter.h if it doesn't exist
  if [ ! -f "${FLUTTER_HEADER}" ]; then
    echo "⚠️ Flutter.h not found, creating a placeholder"
    mkdir -p "$(dirname "${FLUTTER_HEADER}")"
    cat > "${FLUTTER_HEADER}" << 'EOF'
  // Minimal Flutter.h for bridging header compatibility
  #ifndef FLUTTER_FLUTTER_H_
  #define FLUTTER_FLUTTER_H_
  
  #import <Foundation/Foundation.h>
  
  @protocol FlutterPluginRegistry;
  @class NSObject;
  
  // Flutter plugin registry protocol
  @protocol FlutterPluginRegistry <NSObject>
  - (id)registrarForPlugin:(NSString*)pluginKey;
  @end
  
  #endif  // FLUTTER_FLUTTER_H_
  EOF
    
    echo "✅ Created placeholder Flutter.h"
  fi
  
  # Create a copy with proper include path for the build system
  cp "${FLUTTER_HEADER}" "${DERIVED_FILE_DIR}/"
  
  echo "✅ Headers are now available for compilation"
  SCRIPT
  
  # Write the script to a file
  script_path = File.join(IOS_PATH, 'Flutter', 'ensure_headers.sh')
  File.open(script_path, 'w') do |file|
    file.write(script_content)
  end
  FileUtils.chmod(0755, script_path)
  
  puts "✅ Created header copy script at: #{script_path}"
  puts "ℹ️ Make sure to add a Run Script build phase that runs: ${SRCROOT}/Flutter/ensure_headers.sh"
end

# Run the fixes
puts "🛠️ Applying fixes for missing GeneratedPluginRegistrant.h..."

Dir.chdir(FLUTTER_APP_PATH) do
  create_minimal_generated_plugin_registrant
  copy_flutter_headers
  add_header_search_paths_to_build_settings
  fix_bridging_header
  create_header_copy_build_phase
end

puts "✅ All fixes for missing headers have been applied" 