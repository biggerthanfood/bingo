#!/usr/bin/env ruby

# add_ensure_headers_phase.rb
# Adds a build phase to the Xcode project to run the ensure_headers.sh script before compilation

require 'xcodeproj'
require 'fileutils'

# Path to the Xcode project file
PROJECT_PATH = File.join(File.dirname(__FILE__), '..', 'Runner.xcodeproj')

puts "🔧 Adding ensure_headers.sh build phase to Xcode project..."

# Find the project
project = Xcodeproj::Project.open(PROJECT_PATH)
target = project.targets.find { |t| t.name == 'Runner' }

if target
  # Check if the build phase already exists
  ensure_headers_phase = target.shell_script_build_phases.find { |phase| phase.name == 'Ensure Headers' }
  
  if ensure_headers_phase
    puts "⚠️ Ensure Headers build phase already exists, updating it..."
    target.build_phases.delete(ensure_headers_phase)
  end
  
  # Create a new script build phase at the very beginning
  ensure_headers_phase = target.new_shell_script_build_phase
  ensure_headers_phase.name = 'Ensure Headers'
  ensure_headers_phase.shell_script = '${SRCROOT}/Flutter/ensure_headers.sh'
  
  # Move the phase to the beginning before any compilation happens
  target.build_phases.move_from(target.build_phases.count - 1, 0)
  
  # Save the project
  project.save
  
  puts "✅ Successfully added Ensure Headers build phase to Xcode project"
else
  puts "❌ Could not find Runner target in Xcode project"
  exit 1
end 