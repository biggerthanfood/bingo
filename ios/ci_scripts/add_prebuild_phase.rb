#!/usr/bin/env ruby

# add_prebuild_phase.rb
# Adds the pre-build script as the very first build phase in the Xcode project

require 'xcodeproj'
require 'fileutils'

# Path to the Xcode project file
PROJECT_PATH = File.join(File.dirname(__FILE__), '..', 'Runner.xcodeproj')

puts "🔧 Adding pre-build script phase to Xcode project..."

# Find the project
project = Xcodeproj::Project.open(PROJECT_PATH)
target = project.targets.find { |t| t.name == 'Runner' }

if target
  # Check if the build phase already exists
  prebuild_phase = target.shell_script_build_phases.find { |phase| phase.name == 'Run Pre-Build Script' }
  
  if prebuild_phase
    puts "⚠️ Pre-build script phase already exists, updating it..."
    target.build_phases.delete(prebuild_phase)
  end
  
  # Create a new script build phase as the very first phase
  prebuild_phase = target.new_shell_script_build_phase
  prebuild_phase.name = 'Run Pre-Build Script'
  prebuild_phase.shell_script = '${SRCROOT}/ci_scripts/xcode_prebuild.sh'
  
  # Move the phase to the beginning
  target.build_phases.move_from(target.build_phases.count - 1, 0)
  
  # Save the project
  project.save
  
  puts "✅ Successfully added pre-build script phase to Xcode project"
else
  puts "❌ Could not find Runner target in Xcode project"
  exit 1
end 