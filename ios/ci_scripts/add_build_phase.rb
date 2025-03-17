#!/usr/bin/env ruby

# add_build_phase.rb
# Adds a build phase to run our Flutter path fix script before the Flutter build phases

require 'xcodeproj'
require 'pathname'
require 'fileutils'

# Find the actual path of the script relative to this file
script_dir = File.expand_path(File.dirname(__FILE__))
project_path = File.join(script_dir, '..', 'Runner.xcodeproj')

puts "Loading Xcode project from: #{project_path}"
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'Runner' }
unless target
  puts "❌ Error: Runner target not found in Xcode project"
  exit 1
end

# Create a unique ID for our build phase - must be 24 characters
build_phase_id = '3B3967' + ('A'..'Z').to_a.sample(18).join

# Add our build phase script
puts "Adding Flutter Path Fix build phase to Runner target..."

# Find existing script build phases to determine position
flutter_script_phase = nil
target.build_phases.each_with_index do |phase, index|
  if phase.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
    if phase.uuid == '9740EEB61CF901F6004384FC' # Flutter Run Script phase
      flutter_script_phase = phase
      break
    end
  end
end

unless flutter_script_phase
  puts "⚠️ Warning: Could not find Flutter Run Script phase, will add at the beginning"
end

# Check if our build phase already exists
existing_phase = target.build_phases.find do |phase|
  phase.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) &&
    phase.name == 'Run Flutter Path Fix'
end

if existing_phase
  puts "ℹ️ Flutter Path Fix build phase already exists, skipping"
else
  # Create our build phase
  fix_phase = target.new_shell_script_build_phase('Run Flutter Path Fix')
  fix_phase.shell_path = '/bin/sh'
  fix_phase.shell_script = <<~SCRIPT
    # Run the xcode_hook.rb script to fix Flutter paths
    cd "${SRCROOT}/../ios/ci_scripts"
    ruby xcode_hook.rb
  SCRIPT
  
  # Move our phase before the Flutter build phases if we found it
  if flutter_script_phase
    # Find the index where the Flutter phase is
    flutter_index = target.build_phases.index(flutter_script_phase)
    
    # Get our phase's current index (it's at the end)
    fix_index = target.build_phases.index(fix_phase)
    
    # Move our phase to just before the Flutter phase
    if flutter_index && flutter_index > 0
      target.build_phases.move_from(fix_index, flutter_index - 1)
      puts "✅ Positioned Flutter Path Fix build phase just before Flutter Run Script phase"
    end
  end
end

# Save the project
project.save
puts "✅ Successfully updated Xcode project" 