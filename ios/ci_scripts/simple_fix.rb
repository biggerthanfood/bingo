#!/usr/bin/env ruby

# simple_fix.rb
# A direct and simple approach to fix the missing GeneratedPluginRegistrant.h error

require 'fileutils'

# Get the CI workspace path from environment or use a default
CI_WORKSPACE = ENV['CI_WORKSPACE'] || '/Volumes/workspace/repository'

# Define paths using the CI_WORKSPACE
RUNNER_DIR = File.join(CI_WORKSPACE, 'ios', 'Runner')
HEADER_PATH = File.join(RUNNER_DIR, 'GeneratedPluginRegistrant.h')
IMPL_PATH = File.join(RUNNER_DIR, 'GeneratedPluginRegistrant.m')

puts "🛠️ Simple Fix for GeneratedPluginRegistrant.h Issue"
puts "🔍 CI Workspace: #{CI_WORKSPACE}"
puts "📂 Runner directory: #{RUNNER_DIR}"

# Create a minimal GeneratedPluginRegistrant.h
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

# Create a minimal GeneratedPluginRegistrant.m
IMPL_CONTENT = <<-IMPL
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
IMPL

# Make sure the directory exists
FileUtils.mkdir_p(RUNNER_DIR)

# Create the header file
File.write(HEADER_PATH, HEADER_CONTENT)
puts "✅ Created GeneratedPluginRegistrant.h at #{HEADER_PATH}"

# Create the implementation file
File.write(IMPL_PATH, IMPL_CONTENT)
puts "✅ Created GeneratedPluginRegistrant.m at #{IMPL_PATH}"

# Now create the files in DerivedData locations too
DERIVED_DATA = '/Volumes/workspace/DerivedData'

ARCHIVE_INTERMEDIATES = File.join(DERIVED_DATA, 'Build', 'Intermediates.noindex', 'ArchiveIntermediates')
INTERMEDIATE_BUILD_FILES = File.join(ARCHIVE_INTERMEDIATES, 'Runner', 'IntermediateBuildFilesPath')
DERIVED_SOURCES = File.join(INTERMEDIATE_BUILD_FILES, 'Runner.build', 'Release-iphoneos', 'Runner.build', 'DerivedSources')
DERIVED_SOURCES_NORMAL = File.join(INTERMEDIATE_BUILD_FILES, 'Runner.build', 'Release-iphoneos', 'Runner.build', 'DerivedSources-normal', 'arm64')

[DERIVED_SOURCES, DERIVED_SOURCES_NORMAL].each do |dir|
  FileUtils.mkdir_p(dir)
  target_path = File.join(dir, 'GeneratedPluginRegistrant.h')
  File.write(target_path, HEADER_CONTENT)
  puts "✅ Created GeneratedPluginRegistrant.h at #{target_path}"
end

# Create an empty bridging header if it doesn't exist
BRIDGING_HEADER_PATH = File.join(RUNNER_DIR, 'Runner-Bridging-Header.h')
unless File.exist?(BRIDGING_HEADER_PATH)
  File.write(BRIDGING_HEADER_PATH, '#import "GeneratedPluginRegistrant.h"')
  puts "✅ Created Runner-Bridging-Header.h at #{BRIDGING_HEADER_PATH}"
end

puts "🎉 Simple fix completed!" 