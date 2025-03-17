#!/usr/bin/env ruby

# convert_to_objc.rb
# This script converts the Flutter app to use Objective-C instead of Swift for AppDelegate
# This eliminates the need for the Swift bridging header that's causing issues

require 'fileutils'

puts "🔄 Converting Flutter app to use Objective-C AppDelegate instead of Swift..."

# Paths
WORKSPACE_PATH = '/Volumes/workspace'
REPOSITORY_PATH = "#{WORKSPACE_PATH}/repository"
IOS_PATH = "#{REPOSITORY_PATH}/ios"
RUNNER_PATH = "#{IOS_PATH}/Runner"

# 1. Create Objective-C AppDelegate files
APP_DELEGATE_H_CONTENT = <<-OBJC
// AppDelegate.h
// Generated Objective-C version to avoid Swift bridging header issues

#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>

@interface AppDelegate : FlutterAppDelegate

@end
OBJC

APP_DELEGATE_M_CONTENT = <<-OBJC
// AppDelegate.m
// Generated Objective-C version to avoid Swift bridging header issues

#import "AppDelegate.h"
#import <Flutter/Flutter.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
OBJC

MAIN_M_CONTENT = <<-OBJC
// main.m
// Generated main function for Objective-C entry point

#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>
#import "AppDelegate.h"

int main(int argc, char* argv[]) {
  @autoreleasepool {
    return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
  }
}
OBJC

# Create the Objective-C files
puts "📝 Creating Objective-C AppDelegate files..."

# 2. Create the header file
app_delegate_h_path = "#{RUNNER_PATH}/AppDelegate.h"
File.write(app_delegate_h_path, APP_DELEGATE_H_CONTENT)
puts "✅ Created AppDelegate.h at #{app_delegate_h_path}"

# 3. Create the implementation file
app_delegate_m_path = "#{RUNNER_PATH}/AppDelegate.m"
File.write(app_delegate_m_path, APP_DELEGATE_M_CONTENT)
puts "✅ Created AppDelegate.m at #{app_delegate_m_path}"

# 4. Create the main.m file
main_m_path = "#{RUNNER_PATH}/main.m"
File.write(main_m_path, MAIN_M_CONTENT)
puts "✅ Created main.m at #{main_m_path}"

# 5. Create a minimal GeneratedPluginRegistrant.h and .m
plugin_registrant_h_path = "#{RUNNER_PATH}/GeneratedPluginRegistrant.h"
plugin_registrant_m_path = "#{RUNNER_PATH}/GeneratedPluginRegistrant.m"

PLUGIN_REGISTRANT_H_CONTENT = <<-OBJC
//
// Generated file. Do not edit.
//

#ifndef GeneratedPluginRegistrant_h
#define GeneratedPluginRegistrant_h

#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface GeneratedPluginRegistrant : NSObject
+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry;
@end

NS_ASSUME_NONNULL_END

#endif /* GeneratedPluginRegistrant_h */
OBJC

PLUGIN_REGISTRANT_M_CONTENT = <<-OBJC
//
// Generated file. Do not edit.
//

#import "GeneratedPluginRegistrant.h"

#if __has_include(<camera_avfoundation/CameraPlugin.h>)
#import <camera_avfoundation/CameraPlugin.h>
#else
@import camera_avfoundation;
#endif

#if __has_include(<firebase_auth/FLTFirebaseAuthPlugin.h>)
#import <firebase_auth/FLTFirebaseAuthPlugin.h>
#else
@import firebase_auth;
#endif

#if __has_include(<firebase_core/FLTFirebaseCorePlugin.h>)
#import <firebase_core/FLTFirebaseCorePlugin.h>
#else
@import firebase_core;
#endif

#if __has_include(<gal/GalPlugin.h>)
#import <gal/GalPlugin.h>
#else
@import gal;
#endif

#if __has_include(<map_launcher/MapLauncherPlugin.h>)
#import <map_launcher/MapLauncherPlugin.h>
#else
@import map_launcher;
#endif

#if __has_include(<path_provider_foundation/PathProviderPlugin.h>)
#import <path_provider_foundation/PathProviderPlugin.h>
#else
@import path_provider_foundation;
#endif

#if __has_include(<url_launcher_ios/FLTURLLauncherPlugin.h>)
#import <url_launcher_ios/FLTURLLauncherPlugin.h>
#else
@import url_launcher_ios;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [CameraPlugin registerWithRegistrar:[registry registrarForPlugin:@"CameraPlugin"]];
  [FLTFirebaseAuthPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTFirebaseAuthPlugin"]];
  [FLTFirebaseCorePlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTFirebaseCorePlugin"]];
  [GalPlugin registerWithRegistrar:[registry registrarForPlugin:@"GalPlugin"]];
  [MapLauncherPlugin registerWithRegistrar:[registry registrarForPlugin:@"MapLauncherPlugin"]];
  [PathProviderPlugin registerWithRegistrar:[registry registrarForPlugin:@"PathProviderPlugin"]];
  [FLTURLLauncherPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTURLLauncherPlugin"]];
}

@end
OBJC

File.write(plugin_registrant_h_path, PLUGIN_REGISTRANT_H_CONTENT)
puts "✅ Created GeneratedPluginRegistrant.h at #{plugin_registrant_h_path}"

File.write(plugin_registrant_m_path, PLUGIN_REGISTRANT_M_CONTENT)
puts "✅ Created GeneratedPluginRegistrant.m at #{plugin_registrant_m_path}"

# 6. Modify the Xcode project to use Objective-C
puts "🔧 Modifying Runner.xcodeproj to use Objective-C files instead of Swift..."

# Find the project.pbxproj file
project_file = "#{IOS_PATH}/Runner.xcodeproj/project.pbxproj"
if File.exist?(project_file)
  # Create a backup
  backup_file = "#{project_file}.swift_backup"
  if !File.exist?(backup_file)
    FileUtils.cp(project_file, backup_file)
    puts "📦 Created backup of project.pbxproj at #{backup_file}"
  end
  
  content = File.read(project_file)
  
  # Replace AppDelegate.swift references with AppDelegate.m
  if content.include?("AppDelegate.swift")
    content.gsub!("AppDelegate.swift", "AppDelegate.m")
    puts "✅ Replaced AppDelegate.swift references with AppDelegate.m"
  end
  
  # Add AppDelegate.h reference
  if !content.include?("AppDelegate.h")
    content.gsub!(/(.*AppDelegate\.m.*)/) do |match|
      "#{match}\n\t\t\tFileRef = \"AppDelegate.h\";"
    end
    puts "✅ Added AppDelegate.h reference"
  end
  
  # Add main.m reference
  if !content.include?("main.m")
    content.gsub!(/(.*AppDelegate\.m.*)/) do |match|
      "#{match}\n\t\t\tFileRef = \"main.m\";"
    end
    puts "✅ Added main.m reference"
  end
  
  # Remove any SWIFT_* build settings
  if content.include?("SWIFT_OPTIMIZATION_LEVEL")
    content.gsub!(/SWIFT_OPTIMIZATION_LEVEL.*?;/, "")
    puts "✅ Removed SWIFT_OPTIMIZATION_LEVEL settings"
  end
  
  if content.include?("SWIFT_VERSION")
    content.gsub!(/SWIFT_VERSION.*?;/, "")
    puts "✅ Removed SWIFT_VERSION settings"
  end
  
  # Remove any bridging header references
  if content.include?("SWIFT_OBJC_BRIDGING_HEADER")
    content.gsub!(/SWIFT_OBJC_BRIDGING_HEADER.*?;/, "")
    puts "✅ Removed SWIFT_OBJC_BRIDGING_HEADER settings"
  end
  
  # Write the changes back to the file
  File.write(project_file, content)
  puts "✅ Updated project.pbxproj to use Objective-C"
else
  puts "❌ Could not find project.pbxproj at #{project_file}"
end

# 7. Delete Swift files
swift_files = [
  "#{RUNNER_PATH}/AppDelegate.swift",
  "#{RUNNER_PATH}/Runner-Bridging-Header.h"
]

swift_files.each do |file|
  if File.exist?(file)
    # Create a backup
    backup_file = "#{file}.backup"
    if !File.exist?(backup_file)
      FileUtils.cp(file, backup_file)
      puts "📦 Created backup of #{file} at #{backup_file}"
    end
    
    # Delete the file
    File.delete(file)
    puts "✅ Deleted #{file}"
  end
end

puts "🎉 Conversion to Objective-C completed! The app should now build without Swift bridging header issues." 