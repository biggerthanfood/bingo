#!/usr/bin/env ruby

# fix_swift_bridging.rb
# Script to fix Swift compilation and bridging header issues for Xcode Cloud builds

require 'xcodeproj'
require 'fileutils'

# Path to the Xcode project file
PROJECT_PATH = File.join(File.dirname(__FILE__), '..', 'Runner.xcodeproj')

def update_swift_version
  puts "🔧 Updating Swift version settings in Xcode project..."
  
  # Find the project
  project = Xcodeproj::Project.open(PROJECT_PATH)
  target = project.targets.find { |t| t.name == 'Runner' }
  
  if target
    # Iterate through all build configurations
    target.build_configurations.each do |config|
      # Set the Swift version explicitly
      config.build_settings['SWIFT_VERSION'] = '5.0'
      
      # Add the right Swift optimization level for this configuration
      if config.name == 'Release'
        config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-O'
      else
        config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
      end
      
      # Make sure bridging header path is correct
      bridging_header = '$(PROJECT_DIR)/Runner/Runner-Bridging-Header.h'
      config.build_settings['SWIFT_OBJC_BRIDGING_HEADER'] = bridging_header
      
      # Add other Swift-related settings that can help with compilation
      config.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = config.name == 'Debug' ? 'DEBUG' : ''
      
      # Disable Swift whole module optimization for CI builds to reduce memory usage
      config.build_settings['SWIFT_WHOLE_MODULE_OPTIMIZATION'] = 'NO'
      
      puts "✅ Updated Swift settings for #{config.name} configuration"
    end
    
    # Find any project-level Swift settings and update them
    project.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '5.0'
      puts "✅ Updated project-level Swift version for #{config.name} configuration"
    end
    
    # Save the project
    project.save
    puts "✅ Swift version settings updated successfully in Xcode project"
  else
    puts "❌ Could not find Runner target in Xcode project"
    exit 1
  end
end

def verify_bridging_header
  puts "🔍 Verifying Swift bridging header..."
  
  # Path to the bridging header
  bridging_header_path = File.join(File.dirname(__FILE__), '..', 'Runner', 'Runner-Bridging-Header.h')
  
  if File.exist?(bridging_header_path)
    puts "✅ Bridging header exists at: #{bridging_header_path}"
    
    # Read the content of the bridging header
    content = File.read(bridging_header_path)
    
    # Check if it contains the GeneratedPluginRegistrant.h import
    if content.include?('GeneratedPluginRegistrant.h')
      puts "✅ Bridging header content looks good"
    else
      puts "⚠️ Bridging header content might be incorrect, fixing..."
      
      # Add the import if it's missing
      if content.strip.empty?
        File.write(bridging_header_path, "#import \"GeneratedPluginRegistrant.h\"\n")
      else
        # Append the import if the file has content but not the right import
        File.write(bridging_header_path, content + "\n#import \"GeneratedPluginRegistrant.h\"\n")
      end
      
      puts "✅ Fixed bridging header content"
    end
  else
    puts "⚠️ Bridging header file not found, creating it..."
    
    # Create the directory if needed
    FileUtils.mkdir_p(File.dirname(bridging_header_path))
    
    # Create a basic bridging header
    File.write(bridging_header_path, "#import \"GeneratedPluginRegistrant.h\"\n")
    
    puts "✅ Created bridging header: #{bridging_header_path}"
  end
end

def clean_derived_data
  puts "🧹 Cleaning Swift derived data in CI environment..."
  
  # Define paths to clean
  paths_to_clean = [
    "~/Library/Developer/Xcode/DerivedData",
    "#{ENV['CI_WORKSPACE'] || Dir.pwd}/DerivedData",
    "/Volumes/workspace/DerivedData"
  ]
  
  paths_to_clean.each do |path|
    path = File.expand_path(path)
    if Dir.exist?(path)
      puts "Cleaning derived data at: #{path}"
      
      # Remove PrecompiledHeaders directory
      precompiled_path = File.join(path, "PrecompiledHeaders")
      if Dir.exist?(precompiled_path)
        FileUtils.rm_rf(precompiled_path)
        puts "✅ Removed precompiled headers: #{precompiled_path}"
      end
      
      # Remove ModuleCache directory
      module_cache_path = File.join(path, "ModuleCache.noindex")
      if Dir.exist?(module_cache_path)
        FileUtils.rm_rf(module_cache_path)
        puts "✅ Removed module cache: #{module_cache_path}"
      end
    end
  end
  
  puts "✅ Cleaned Swift derived data"
end

def add_swift_preprocessing_script
  puts "🔧 Adding Swift preprocessing script..."
  
  # Find the project
  project = Xcodeproj::Project.open(PROJECT_PATH)
  target = project.targets.find { |t| t.name == 'Runner' }
  
  if target
    # Check if the build phase already exists
    swift_phase = target.shell_script_build_phases.find { |phase| phase.name == 'Swift Preprocessing' }
    
    if swift_phase
      puts "⚠️ Swift preprocessing phase already exists, updating it..."
      # Remove the existing phase to add a new one with updated script
      target.build_phases.delete(swift_phase)
    end
    
    # Create a new script build phase before the 'Compile Sources' phase
    insert_at_index = nil
    target.build_phases.each_with_index do |phase, index|
      if phase.is_a?(Xcodeproj::Project::Object::PBXSourcesBuildPhase)
        insert_at_index = index
        break
      end
    end
    
    # If we couldn't find the right spot, add it at the beginning
    insert_at_index ||= 0
    
    # Create the new build phase
    swift_phase = target.new_shell_script_build_phase
    swift_phase.name = 'Swift Preprocessing'
    
    # The shell script to ensure Swift compilation works correctly
    swift_phase.shell_script = <<~SCRIPT
    #!/bin/sh
    
    # Script to prepare Swift environment and clean any problematic cache
    
    echo "🔧 Preparing Swift environment..."
    
    # Create a clean environment for bridging header
    DERIVED_FILE_DIR="${OBJROOT}/DerivedSources"
    PRECOMP_PATH="${OBJROOT}/PrecompiledHeaders"
    
    # Ensure directories exist
    mkdir -p "${DERIVED_FILE_DIR}"
    mkdir -p "${PRECOMP_PATH}"
    
    # Copy bridging header to derived sources if it exists
    BRIDGING_HEADER="${SRCROOT}/Runner/Runner-Bridging-Header.h"
    if [ -f "${BRIDGING_HEADER}" ]; then
      echo "✅ Copying bridging header to derived sources"
      cp "${BRIDGING_HEADER}" "${DERIVED_FILE_DIR}/Runner-Bridging-Header.h"
    else
      echo "⚠️ Bridging header not found at: ${BRIDGING_HEADER}"
      # Create a basic bridging header in derived sources
      echo "#import \\"GeneratedPluginRegistrant.h\\"" > "${DERIVED_FILE_DIR}/Runner-Bridging-Header.h"
      echo "✅ Created default bridging header in derived sources"
    fi
    
    # Touch the bridging header to ensure it's fresh
    touch "${DERIVED_FILE_DIR}/Runner-Bridging-Header.h"
    
    # Also set permissions to ensure it's readable
    chmod 644 "${DERIVED_FILE_DIR}/Runner-Bridging-Header.h"
    
    echo "✅ Swift environment prepared successfully"
    SCRIPT
    
    # Move the build phase to the right position
    target.build_phases.move_from(target.build_phases.count - 1, insert_at_index)
    
    # Save the project
    project.save
    
    puts "✅ Successfully added Swift preprocessing phase to Xcode project"
  else
    puts "❌ Could not find Runner target in Xcode project"
    exit 1
  end
end

# Run all the fixes
puts "🛠️ Running Swift fixes for Xcode Cloud..."

verify_bridging_header
update_swift_version
clean_derived_data
add_swift_preprocessing_script

puts "✅ All Swift fixes have been applied" 