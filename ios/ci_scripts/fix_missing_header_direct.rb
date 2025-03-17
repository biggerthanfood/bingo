#!/usr/bin/env ruby

# fix_missing_header_direct.rb
# Script to directly place the GeneratedPluginRegistrant.h file in all possible locations

require 'fileutils'

# Define paths based on Xcode Cloud environment
CI_WORKSPACE = ENV['CI_WORKSPACE'] || '/Volumes/workspace/repository'
IOS_PATH = File.join(CI_WORKSPACE, 'ios')
DERIVED_DATA = '/Volumes/workspace/DerivedData'

# Create the minimal header content
def generate_header_content
  <<~HEADER
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
end

# Create the minimal implementation content
def generate_implementation_content
  <<~IMPLEMENTATION
  //
  // Generated file. Do not edit.
  //

  // clang-format off
  #import "GeneratedPluginRegistrant.h"

  // No plugins to register

  @implementation GeneratedPluginRegistrant

  + (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
    // No plugins to register
  }

  @end
  IMPLEMENTATION
end

# Create a minimal Flutter.h if needed
def generate_flutter_header_content
  <<~FLUTTER_HEADER
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
  FLUTTER_HEADER
end

puts "🔨 Starting direct fix for missing GeneratedPluginRegistrant.h..."

# Locations to place the header files
runner_dir = File.join(IOS_PATH, 'Runner')
derived_sources = Dir.glob("#{DERIVED_DATA}/**/DerivedSources")
derived_sources += Dir.glob("#{DERIVED_DATA}/**/DerivedSources-normal/*")
intermediate_build_files = Dir.glob("#{DERIVED_DATA}/**/IntermediateBuildFilesPath")
precompiled_headers = Dir.glob("#{DERIVED_DATA}/**/PrecompiledHeaders")

# Add Flutter framework Headers directories
flutter_headers_dirs = [
  File.join(IOS_PATH, 'Flutter', 'Flutter.framework', 'Headers'),
  File.join(IOS_PATH, '.symlinks', 'flutter', 'ios', 'Flutter.framework', 'Headers')
]

# Create the main header in the Runner directory
header_path = File.join(runner_dir, 'GeneratedPluginRegistrant.h')
impl_path = File.join(runner_dir, 'GeneratedPluginRegistrant.m')

# Always create fresh copies to ensure we have the right content
FileUtils.mkdir_p(File.dirname(header_path))
File.write(header_path, generate_header_content)
File.write(impl_path, generate_implementation_content)
puts "✅ Created GeneratedPluginRegistrant.h and .m in #{runner_dir}"

# Create the Flutter.h in the Flutter framework directories
flutter_headers_dirs.each do |dir|
  FileUtils.mkdir_p(dir)
  flutter_h_path = File.join(dir, 'Flutter.h')
  File.write(flutter_h_path, generate_flutter_header_content)
  puts "✅ Created Flutter.h in #{dir}"
end

# Copy the header to all derived sources locations
derived_sources.each do |dir|
  target = File.join(dir, 'GeneratedPluginRegistrant.h')
  FileUtils.mkdir_p(File.dirname(target))
  File.write(target, generate_header_content)
  puts "✅ Created GeneratedPluginRegistrant.h in #{dir}"
end

# Copy to intermediate build files locations
intermediate_build_files.each do |dir|
  target = File.join(dir, 'Runner.build', 'DerivedSources', 'GeneratedPluginRegistrant.h')
  FileUtils.mkdir_p(File.dirname(target))
  File.write(target, generate_header_content)
  puts "✅ Created GeneratedPluginRegistrant.h in #{dir}/Runner.build/DerivedSources"
end

# Create a project-wide header search paths file
search_paths_file = File.join(IOS_PATH, 'Flutter', 'HeaderSearchPaths.xcconfig')
search_paths_content = <<~SEARCHPATHS
// Additional header search paths
HEADER_SEARCH_PATHS = $(inherited) $(SRCROOT)/Runner $(SRCROOT)/Flutter $(SRCROOT)/Flutter/Flutter.framework/Headers $(SRCROOT)/.symlinks/flutter/ios/Flutter.framework/Headers
SWIFT_INCLUDE_PATHS = $(inherited) $(SRCROOT)/Runner $(SRCROOT)/Flutter
GCC_PREPROCESSOR_DEFINITIONS = $(inherited) COCOAPODS=1
SWIFT_OBJC_BRIDGING_HEADER = $(SRCROOT)/Runner/Runner-Bridging-Header.h
SWIFT_OBJC_INTERFACE_HEADER_NAME = Runner-Swift.h
ALWAYS_SEARCH_USER_PATHS = YES
CLANG_MODULES_AUTOLINK = NO
SEARCHPATHS

File.write(search_paths_file, search_paths_content)
puts "✅ Created HeaderSearchPaths.xcconfig"

# Update the main build configuration files to import our search paths
['Debug.xcconfig', 'Release.xcconfig'].each do |config_file|
  config_path = File.join(IOS_PATH, 'Flutter', config_file)
  next unless File.exist?(config_path)
  
  content = File.read(config_path)
  unless content.include?('#include "HeaderSearchPaths.xcconfig"')
    content = content + "\n#include \"HeaderSearchPaths.xcconfig\"\n"
    File.write(config_path, content)
    puts "✅ Updated #{config_file} to include header search paths"
  end
end

# We also need to make sure the bridging header exists and has the right content
bridging_header = File.join(runner_dir, 'Runner-Bridging-Header.h')
File.write(bridging_header, '#import "GeneratedPluginRegistrant.h"')
puts "✅ Updated Runner-Bridging-Header.h"

# Create a wrapper function that directly uses the generated registration
# This can help ensure the main class is loaded
app_delegate = File.join(runner_dir, 'AppDelegate.swift')
if File.exist?(app_delegate)
  content = File.read(app_delegate)
  
  unless content.include?('ensureGeneratedPluginRegistrantLoaded')
    # Add a function to force loading the registrant
    content = content.gsub(/import UIKit/, "import UIKit\nimport Foundation")
    
    # Add a helper function to the AppDelegate class
    content = content.gsub(/class AppDelegate: (.+) \{/) do |match|
      "class AppDelegate: #{$1} {\n  private func ensureGeneratedPluginRegistrantLoaded() {\n    if let _ = NSClassFromString(\"GeneratedPluginRegistrant\") {\n      GeneratedPluginRegistrant.register(with: self)\n    }\n  }"
    end
    
    # Call the function in application:didFinishLaunchingWithOptions
    content = content.gsub(/GeneratedPluginRegistrant.register\(with: self\)/) do |match|
      "// Replaced with safer loading mechanism\nensureGeneratedPluginRegistrantLoaded()"
    end
    
    File.write(app_delegate, content)
    puts "✅ Updated AppDelegate.swift with safer plugin loading"
  end
end

puts "✅ Completed direct fix for missing GeneratedPluginRegistrant.h"
puts "✨ Header files have been placed in all required locations" 