#!/usr/bin/env ruby

# install_hooks.rb
# This script adds a pre-build hook to the Runner project's default scheme

require 'xcodeproj'
require 'fileutils'

puts "🔧 Installing build hooks in Xcode project..."

# Path to the Xcode project
project_path = File.join(File.dirname(__FILE__), '..', 'Runner.xcodeproj')

# Path to the default scheme
scheme_path = File.join(project_path, 'xcshareddata', 'xcschemes', 'Runner.xcscheme')

if File.exist?(scheme_path)
  puts "Found scheme: #{scheme_path}"
  
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
            title = "Fix GeneratedPluginRegistrant.h"
            scriptText = "# Fix for missing GeneratedPluginRegistrant.h&#10;cd &quot;${SRCROOT}/..&quot;&#10;ruby &quot;${SRCROOT}/ci_scripts/simple_fix.rb&quot;&#10;">
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

# Also create a file for our build phase
build_phase_script = File.join(File.dirname(__FILE__), '..', 'ensure_header.sh')
File.open(build_phase_script, 'w') do |file|
  file.puts '#!/bin/sh'
  file.puts ''
  file.puts '# ensure_header.sh'
  file.puts '# Script that ensures GeneratedPluginRegistrant.h exists'
  file.puts ''
  file.puts 'HEADER_PATH="${SRCROOT}/Runner/GeneratedPluginRegistrant.h"'
  file.puts 'IMPL_PATH="${SRCROOT}/Runner/GeneratedPluginRegistrant.m"'
  file.puts ''
  file.puts 'echo "🔍 Checking for GeneratedPluginRegistrant.h at: ${HEADER_PATH}"'
  file.puts ''
  file.puts 'if [ ! -f "${HEADER_PATH}" ]; then'
  file.puts '  echo "⚠️ GeneratedPluginRegistrant.h not found, creating it..."'
  file.puts ''
  file.puts '  # Create the minimal header file'
  file.puts '  cat > "${HEADER_PATH}" << EOF'
  file.puts '//'
  file.puts '// Generated file. Do not edit.'
  file.puts '//'
  file.puts ''
  file.puts '// clang-format off'
  file.puts '#ifndef GeneratedPluginRegistrant_h'
  file.puts '#define GeneratedPluginRegistrant_h'
  file.puts ''
  file.puts '#import <Foundation/Foundation.h>'
  file.puts ''
  file.puts 'NS_ASSUME_NONNULL_BEGIN'
  file.puts ''
  file.puts '@protocol FlutterPluginRegistry;'
  file.puts ''
  file.puts '@interface GeneratedPluginRegistrant : NSObject'
  file.puts '+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry;'
  file.puts '@end'
  file.puts ''
  file.puts 'NS_ASSUME_NONNULL_END'
  file.puts '#endif /* GeneratedPluginRegistrant_h */'
  file.puts 'EOF'
  file.puts ''
  file.puts '  echo "✅ Created GeneratedPluginRegistrant.h"'
  file.puts 'else'
  file.puts '  echo "✅ GeneratedPluginRegistrant.h already exists"'
  file.puts 'fi'
  file.puts ''
  file.puts '# Also create or check the implementation file'
  file.puts 'if [ ! -f "${IMPL_PATH}" ]; then'
  file.puts '  echo "⚠️ GeneratedPluginRegistrant.m not found, creating it..."'
  file.puts ''
  file.puts '  # Create the minimal implementation file'
  file.puts '  cat > "${IMPL_PATH}" << EOF'
  file.puts '//'
  file.puts '// Generated file. Do not edit.'
  file.puts '//'
  file.puts ''
  file.puts '// clang-format off'
  file.puts '#import "GeneratedPluginRegistrant.h"'
  file.puts ''
  file.puts '// No plugins to register'
  file.puts ''
  file.puts '@implementation GeneratedPluginRegistrant'
  file.puts ''
  file.puts '+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {'
  file.puts '  // No plugins to register'
  file.puts '}'
  file.puts ''
  file.puts '@end'
  file.puts 'EOF'
  file.puts ''
  file.puts '  echo "✅ Created GeneratedPluginRegistrant.m"'
  file.puts 'else'
  file.puts '  echo "✅ GeneratedPluginRegistrant.m already exists"'
  file.puts 'fi'
  file.puts ''
  file.puts 'echo "✅ Header files verified"'
end

# Make the script executable
FileUtils.chmod(0755, build_phase_script)
puts "✅ Created build phase script at: #{build_phase_script}"

# Now add the script as a build phase if not already present
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Runner' }

if target
  # Check if our ensure headers phase already exists
  ensure_phase = target.shell_script_build_phases.find { |phase| phase.name == 'Ensure GeneratedPluginRegistrant.h' }
  
  if ensure_phase
    # Update the phase
    ensure_phase.shell_script = '"${SRCROOT}/ensure_header.sh"'
    puts "⚠️ Updated existing Ensure GeneratedPluginRegistrant.h build phase"
  else
    # Create a new script phase at the beginning
    ensure_phase = target.new_shell_script_build_phase('Ensure GeneratedPluginRegistrant.h')
    ensure_phase.shell_script = '"${SRCROOT}/ensure_header.sh"'
    
    # Move it to be the first phase
    target.build_phases.move_from(target.build_phases.count - 1, 0)
    puts "✅ Added Ensure GeneratedPluginRegistrant.h build phase"
  end
  
  # Save changes to the project
  project.save
else
  puts "❌ Couldn't find Runner target in project"
end

puts "🎉 Build hooks installation completed!" 