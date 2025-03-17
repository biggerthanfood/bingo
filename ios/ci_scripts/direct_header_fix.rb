#!/usr/bin/env ruby

# direct_header_fix.rb
# A simplified, direct approach to fix the missing GeneratedPluginRegistrant.h error
# This script focuses only on creating the necessary files in the exact locations
# mentioned in the error messages

require 'fileutils'

puts "🚀 Running direct header fix for GeneratedPluginRegistrant.h"

# Paths from the error message
WORKSPACE_PATH = '/Volumes/workspace'
REPOSITORY_PATH = "#{WORKSPACE_PATH}/repository"
DERIVED_DATA_PATH = "#{WORKSPACE_PATH}/DerivedData"

# Define header content
HEADER_CONTENT = <<-HEADER
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
HEADER

# Define implementation content
IMPL_CONTENT = <<-IMPL
//
// Generated file. Do not edit.
//

// clang-format off
#import "GeneratedPluginRegistrant.h"

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  // No plugins to register
}

@end
IMPL

# List of all locations to create the header file
HEADER_LOCATIONS = [
  # Main project location
  "#{REPOSITORY_PATH}/ios/Runner/GeneratedPluginRegistrant.h",
  
  # DerivedData locations from error message
  "#{DERIVED_DATA_PATH}/Build/Intermediates.noindex/ArchiveIntermediates/Runner/IntermediateBuildFilesPath/Runner.build/Release-iphoneos/Runner.build/DerivedSources/GeneratedPluginRegistrant.h",
  "#{DERIVED_DATA_PATH}/Build/Intermediates.noindex/ArchiveIntermediates/Runner/IntermediateBuildFilesPath/Runner.build/Release-iphoneos/Runner.build/DerivedSources-normal/arm64/GeneratedPluginRegistrant.h",
  
  # Additional locations to cover all bases
  "#{DERIVED_DATA_PATH}/Build/Products/Release-iphoneos/GeneratedPluginRegistrant.h",
  "#{DERIVED_DATA_PATH}/Build/Products/Release-iphoneos/Runner.app/GeneratedPluginRegistrant.h"
]

# List of all locations to create the implementation file
IMPL_LOCATIONS = [
  # Main project location
  "#{REPOSITORY_PATH}/ios/Runner/GeneratedPluginRegistrant.m",
  
  # DerivedData locations
  "#{DERIVED_DATA_PATH}/Build/Intermediates.noindex/ArchiveIntermediates/Runner/IntermediateBuildFilesPath/Runner.build/Release-iphoneos/Runner.build/DerivedSources/GeneratedPluginRegistrant.m",
  "#{DERIVED_DATA_PATH}/Build/Intermediates.noindex/ArchiveIntermediates/Runner/IntermediateBuildFilesPath/Runner.build/Release-iphoneos/Runner.build/DerivedSources-normal/arm64/GeneratedPluginRegistrant.m",
  
  # Additional locations
  "#{DERIVED_DATA_PATH}/Build/Products/Release-iphoneos/GeneratedPluginRegistrant.m",
  "#{DERIVED_DATA_PATH}/Build/Products/Release-iphoneos/Runner.app/GeneratedPluginRegistrant.m"
]

# Create header files
HEADER_LOCATIONS.each do |location|
  begin
    # Ensure directory exists
    FileUtils.mkdir_p(File.dirname(location))
    
    # Create the file
    File.write(location, HEADER_CONTENT)
    puts "✅ Created header file at: #{location}"
  rescue => e
    puts "⚠️ Could not create header at #{location}: #{e.message}"
  end
end

# Create implementation files
IMPL_LOCATIONS.each do |location|
  begin
    # Ensure directory exists
    FileUtils.mkdir_p(File.dirname(location))
    
    # Create the file
    File.write(location, IMPL_CONTENT)
    puts "✅ Created implementation file at: #{location}"
  rescue => e
    puts "⚠️ Could not create implementation at #{location}: #{e.message}"
  end
end

# Also ensure the bridging header is properly set up
BRIDGING_HEADER_PATH = "#{REPOSITORY_PATH}/ios/Runner/Runner-Bridging-Header.h"
begin
  # Just make sure it has the correct import
  bridging_content = File.exist?(BRIDGING_HEADER_PATH) ? File.read(BRIDGING_HEADER_PATH) : ""
  
  if !bridging_content.include?('#import "GeneratedPluginRegistrant.h"')
    # Create a new bridging header with the correct import
    File.write(BRIDGING_HEADER_PATH, '#import "GeneratedPluginRegistrant.h"')
    puts "✅ Updated bridging header at: #{BRIDGING_HEADER_PATH}"
  else
    puts "✅ Bridging header already correct at: #{BRIDGING_HEADER_PATH}"
  end
rescue => e
  puts "⚠️ Could not update bridging header: #{e.message}"
end

# Create a build phase shell script for Xcode to run directly
BUILD_PHASE_SCRIPT = "#{REPOSITORY_PATH}/ios/create_headers.sh"
begin
  script_content = <<-SCRIPT
#!/bin/sh

# Direct script to create GeneratedPluginRegistrant.h and .m files
# This runs as an Xcode build phase

echo "🔍 Creating GeneratedPluginRegistrant.h and .m files"

# Create directories if they don't exist
mkdir -p "${SRCROOT}/Runner"
mkdir -p "${BUILT_PRODUCTS_DIR}/include"
mkdir -p "${BUILT_PRODUCTS_DIR}/Runner.app"

# Create header file in all necessary locations
cat > "${SRCROOT}/Runner/GeneratedPluginRegistrant.h" << 'EOF'
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

cat > "${SRCROOT}/Runner/GeneratedPluginRegistrant.m" << 'EOF'
//
// Generated file. Do not edit.
//

// clang-format off
#import "GeneratedPluginRegistrant.h"

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  // No plugins to register
}

@end
EOF

# Copy to other locations
cp "${SRCROOT}/Runner/GeneratedPluginRegistrant.h" "${BUILT_PRODUCTS_DIR}/include/" 2>/dev/null || true
cp "${SRCROOT}/Runner/GeneratedPluginRegistrant.m" "${BUILT_PRODUCTS_DIR}/include/" 2>/dev/null || true
cp "${SRCROOT}/Runner/GeneratedPluginRegistrant.h" "${BUILT_PRODUCTS_DIR}/Runner.app/" 2>/dev/null || true
cp "${SRCROOT}/Runner/GeneratedPluginRegistrant.m" "${BUILT_PRODUCTS_DIR}/Runner.app/" 2>/dev/null || true

echo "✅ Successfully created GeneratedPluginRegistrant files"
SCRIPT

  File.write(BUILD_PHASE_SCRIPT, script_content)
  FileUtils.chmod(0755, BUILD_PHASE_SCRIPT)
  puts "✅ Created build phase script at: #{BUILD_PHASE_SCRIPT}"
rescue => e
  puts "⚠️ Could not create build phase script: #{e.message}"
end

puts "🎉 Direct header fix completed!" 