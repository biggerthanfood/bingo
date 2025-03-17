#!/usr/bin/env ruby

# improved_project_fixer.rb
# A more advanced script to fix Xcode project file references and build settings

require 'xcodeproj'

puts "🔧 Running improved Xcode project fixer..."

# Paths
project_path = File.join(File.dirname(__FILE__), '..', 'Runner.xcodeproj')

begin
  # Open the Xcode project
  project = Xcodeproj::Project.open(project_path)
  puts "✅ Opened Xcode project at: #{project_path}"
  
  # Find the Runner target
  target = project.targets.find { |t| t.name == 'Runner' }
  
  if !target
    puts "❌ Could not find Runner target in project"
    exit 1
  end
  
  puts "✅ Found Runner target"
  
  # Get the main group
  main_group = project.main_group
  runner_group = main_group.find_subpath('Runner', true)
  
  # File paths
  file_paths = {
    'AppDelegate.h' => 'Runner/AppDelegate.h',
    'AppDelegate.m' => 'Runner/AppDelegate.m',
    'main.m' => 'Runner/main.m',
    'GeneratedPluginRegistrant.h' => 'Runner/GeneratedPluginRegistrant.h',
    'GeneratedPluginRegistrant.m' => 'Runner/GeneratedPluginRegistrant.m'
  }
  
  # Find existing files to avoid duplicates
  existing_files = []
  runner_group.files.each do |file|
    existing_files << file.path
  end
  
  # Add new Objective-C files to the project
  files_to_add = []
  
  file_paths.each do |name, path|
    # Check if this file is already in the project
    if !existing_files.include?(name) && !runner_group.find_file_by_path(name)
      file_ref = runner_group.new_file(path)
      files_to_add << file_ref
      puts "✅ Added file reference for #{name}"
    else
      puts "⚠️ File #{name} already exists in project"
    end
  end
  
  # Add new files to the target's sources build phase
  if !files_to_add.empty?
    sources_build_phase = target.source_build_phase
    
    files_to_add.each do |file|
      # Only add files that aren't already in the build phase
      if !sources_build_phase.files.find { |build_file| build_file.file_ref == file }
        sources_build_phase.add_file_reference(file)
        puts "✅ Added #{file.path} to target's sources build phase"
      end
    end
  end
  
  # Remove Swift files from project and build phase
  swift_files = runner_group.files.select { |f| f.path.end_with?('.swift') }
  
  swift_files.each do |swift_file|
    # Remove from build phases first
    target.build_phases.each do |phase|
      phase.files.each do |build_file|
        if build_file.file_ref == swift_file
          phase.remove_build_file(build_file)
          puts "✅ Removed #{swift_file.path} from build phase"
        end
      end
    end
    
    # Then remove from project
    swift_file.remove_from_project
    puts "✅ Removed #{swift_file.path} from project"
  end
  
  # Fix build configurations
  target.build_configurations.each do |config|
    # Remove all Swift-related build settings
    swift_settings = [
      'SWIFT_OBJC_BRIDGING_HEADER',
      'SWIFT_OPTIMIZATION_LEVEL',
      'SWIFT_VERSION',
      'SWIFT_ACTIVE_COMPILATION_CONDITIONS'
    ]
    
    swift_settings.each do |setting|
      if config.build_settings[setting]
        config.build_settings.delete(setting)
        puts "✅ Removed #{setting} from #{config.name} configuration"
      end
    end
    
    # Add CLANG_ENABLE_MODULES to ensure modules work
    config.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
    
    # Make sure the proper framework search paths are set
    if !config.build_settings['FRAMEWORK_SEARCH_PATHS']
      config.build_settings['FRAMEWORK_SEARCH_PATHS'] = '$(inherited) "${PODS_CONFIGURATION_BUILD_DIR}/camera_avfoundation" "${PODS_CONFIGURATION_BUILD_DIR}/firebase_auth" "${PODS_CONFIGURATION_BUILD_DIR}/firebase_core" "${PODS_CONFIGURATION_BUILD_DIR}/gal" "${PODS_CONFIGURATION_BUILD_DIR}/map_launcher" "${PODS_CONFIGURATION_BUILD_DIR}/path_provider_foundation" "${PODS_CONFIGURATION_BUILD_DIR}/url_launcher_ios"'
      puts "✅ Added FRAMEWORK_SEARCH_PATHS to #{config.name} configuration"
    end
  end
  
  # Save the project
  project.save
  puts "✅ Saved changes to Xcode project"
  
  # Now fix the project scheme
  puts "🔧 Fixing Xcode scheme..."
  scheme_path = File.join(project_path, 'xcshareddata', 'xcschemes', 'Runner.xcscheme')
  
  if File.exist?(scheme_path)
    # Create a backup of the scheme
    FileUtils.cp(scheme_path, "#{scheme_path}.backup") unless File.exist?("#{scheme_path}.backup")
    
    # Read the scheme file
    scheme_content = File.read(scheme_path)
    
    # Look for Swift-specific settings and remove them
    if scheme_content.include?('SWIFT_ACTIVE_COMPILATION_CONDITIONS')
      scheme_content.gsub!(/SWIFT_ACTIVE_COMPILATION_CONDITIONS.*?\n/, '')
      puts "✅ Removed SWIFT_ACTIVE_COMPILATION_CONDITIONS from scheme"
    end
    
    # Write the changes back to the file
    File.write(scheme_path, scheme_content)
    puts "✅ Updated Xcode scheme"
  else
    puts "⚠️ Could not find Runner.xcscheme"
  end
  
  puts "🎉 Xcode project fixing completed successfully!"
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace
  exit 1
end 