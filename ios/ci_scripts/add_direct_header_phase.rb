#!/usr/bin/env ruby

# add_direct_header_phase.rb
# Adds a build phase to ensure GeneratedPluginRegistrant.h exists at build time

require 'xcodeproj'
require 'fileutils'

puts "🔧 Adding direct header fix build phase to Xcode project..."

# Path to the Xcode project
project_path = File.join(File.dirname(__FILE__), '..', 'Runner.xcodeproj')

# First, ensure the shell script exists
script_path = File.join(File.dirname(__FILE__), '..', 'create_headers.sh')
if !File.exist?(script_path)
  # Run the direct header fix script to create it
  direct_fix_script = File.join(File.dirname(__FILE__), 'direct_header_fix.rb')
  if File.exist?(direct_fix_script)
    system("ruby #{direct_fix_script}")
  else
    puts "⚠️ Could not find direct_header_fix.rb script"
  end
end

if !File.exist?(script_path)
  puts "❌ Could not find or create shell script at #{script_path}"
  exit 1
end

# Make sure the script is executable
FileUtils.chmod(0755, script_path)

# Open the Xcode project
begin
  project = Xcodeproj::Project.open(project_path)
  puts "✅ Opened Xcode project: #{project_path}"
rescue => e
  puts "❌ Could not open Xcode project: #{e.message}"
  exit 1
end

# Find the main target
target = project.targets.find { |t| t.name == 'Runner' }
if !target
  puts "❌ Could not find Runner target in project"
  exit 1
end

puts "✅ Found Runner target"

# Check if our header generation phase already exists
header_phase = target.shell_script_build_phases.find { |phase| phase.name == 'Generate Missing Headers' }

if header_phase
  # Update the existing phase
  header_phase.shell_script = '"${SRCROOT}/create_headers.sh"'
  puts "✅ Updated existing Generate Missing Headers build phase"
else
  # Create a new build phase for header generation
  header_phase = target.new_shell_script_build_phase('Generate Missing Headers')
  header_phase.shell_script = '"${SRCROOT}/create_headers.sh"'
  
  # Move it to the beginning (position 0) to ensure it runs first
  if target.build_phases.count > 1
    target.build_phases.move_from(target.build_phases.count - 1, 0)
    puts "✅ Added Generate Missing Headers build phase at position 0"
  else
    puts "✅ Added Generate Missing Headers build phase"
  end
end

# Disable sandbox for this script phase
header_phase.input_paths = []
header_phase.output_paths = []

# Save the project
begin
  project.save
  puts "✅ Saved Xcode project with new build phase"
rescue => e
  puts "❌ Could not save Xcode project: #{e.message}"
  exit 1
end

# Also add a pre-build action to the scheme
scheme_path = File.join(project_path, 'xcshareddata', 'xcschemes', 'Runner.xcscheme')
if File.exist?(scheme_path)
  puts "✅ Found scheme: #{scheme_path}"
  
  # Backup the scheme
  FileUtils.cp(scheme_path, "#{scheme_path}.backup")
  
  # Read the scheme file
  scheme_content = File.read(scheme_path)
  
  # Define our pre-build script
  pre_build_script = <<-SCRIPT
   <PreBuildActions>
      <ExecutionAction
         ActionType = "Xcode.IDEStandardExecutionActionsCore.ExecutionActionType.ShellScriptAction">
         <ActionContent
            title = "Generate Missing Headers"
            scriptText = "cd &quot;${SRCROOT}/..&quot;&#10;ruby &quot;${SRCROOT}/ci_scripts/direct_header_fix.rb&quot;&#10;">
            <EnvironmentBuildable>
               <BuildableReference
                  BuildableIdentifier = "primary"
                  BlueprintIdentifier = "97C146ED1CF9000F007C117D"
                  BuildableName = "Runner.app"
                  BlueprintName = "Runner"
                  ReferencedContainer = "container:Runner.xcodeproj">
               </BuildableReference>
            </EnvironmentBuildable>
         </ActionContent>
      </ExecutionAction>
   </PreBuildActions>
  SCRIPT
  
  # Check if BuildActionEntries is present, we'll insert our pre-build script before it
  if scheme_content.include?("<BuildActionEntries>")
    if !scheme_content.include?("<PreBuildActions>")
      # Insert the pre-build script before BuildActionEntries
      scheme_content.gsub!(/<BuildActionEntries>/, "#{pre_build_script}\n   <BuildActionEntries>")
      
      # Write back to the file
      File.write(scheme_path, scheme_content)
      puts "✅ Added pre-build script to Runner.xcscheme"
    else
      puts "⚠️ Pre-build actions already exist in scheme"
    end
  else
    puts "❌ Couldn't find BuildActionEntries in scheme"
  end
else
  puts "❌ Runner.xcscheme not found"
end

puts "🎉 Build phase addition completed!" 