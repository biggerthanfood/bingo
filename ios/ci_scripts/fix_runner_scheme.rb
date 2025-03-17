#!/usr/bin/env ruby

# fix_runner_scheme.rb
# This script ensures that the Runner scheme is properly shared and accessible in the workspace

require 'fileutils'

puts "🔧 Fixing Runner scheme for Xcode Cloud build..."

# Paths
workspace_dir = File.expand_path(File.join(__dir__, '..', 'Runner.xcworkspace'))
project_dir = File.expand_path(File.join(__dir__, '..', 'Runner.xcodeproj'))

# Create xcshareddata/xcschemes directories in workspace if they don't exist
workspace_schemes_dir = File.join(workspace_dir, 'xcshareddata', 'xcschemes')
FileUtils.mkdir_p(workspace_schemes_dir)
puts "✅ Created or verified workspace schemes directory: #{workspace_schemes_dir}"

# Check if the scheme exists in the project
project_scheme_path = File.join(project_dir, 'xcshareddata', 'xcschemes', 'Runner.xcscheme')
workspace_scheme_path = File.join(workspace_schemes_dir, 'Runner.xcscheme')

if File.exist?(project_scheme_path)
  puts "✅ Found Runner scheme in project: #{project_scheme_path}"
  
  # Copy the scheme to the workspace if it doesn't exist or if it's different
  if !File.exist?(workspace_scheme_path) || File.read(project_scheme_path) != File.read(workspace_scheme_path)
    FileUtils.cp(project_scheme_path, workspace_scheme_path)
    puts "✅ Copied Runner scheme to workspace: #{workspace_scheme_path}"
  else
    puts "✅ Runner scheme already exists in workspace and is up to date"
  end
else
  puts "❌ Runner scheme not found in project, creating a default one..."
  
  # Create a basic Runner scheme file
  scheme_content = <<~XML
  <?xml version="1.0" encoding="UTF-8"?>
  <Scheme
     LastUpgradeVersion = "1300"
     version = "1.3">
     <BuildAction
        parallelizeBuildables = "YES"
        buildImplicitDependencies = "YES">
        <BuildActionEntries>
           <BuildActionEntry
              buildForTesting = "YES"
              buildForRunning = "YES"
              buildForProfiling = "YES"
              buildForArchiving = "YES"
              buildForAnalyzing = "YES">
              <BuildableReference
                 BuildableIdentifier = "primary"
                 BlueprintIdentifier = "97C146ED1CF9000F007C117D"
                 BuildableName = "Runner.app"
                 BlueprintName = "Runner"
                 ReferencedContainer = "container:Runner.xcodeproj">
              </BuildableReference>
           </BuildActionEntry>
        </BuildActionEntries>
     </BuildAction>
     <TestAction
        buildConfiguration = "Debug"
        selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
        selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
        shouldUseLaunchSchemeArgsEnv = "YES">
        <Testables>
        </Testables>
     </TestAction>
     <LaunchAction
        buildConfiguration = "Debug"
        selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
        selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
        launchStyle = "0"
        useCustomWorkingDirectory = "NO"
        ignoresPersistentStateOnLaunch = "NO"
        debugDocumentVersioning = "YES"
        debugServiceExtension = "internal"
        allowLocationSimulation = "YES">
        <BuildableProductRunnable
           runnableDebuggingMode = "0">
           <BuildableReference
              BuildableIdentifier = "primary"
              BlueprintIdentifier = "97C146ED1CF9000F007C117D"
              BuildableName = "Runner.app"
              BlueprintName = "Runner"
              ReferencedContainer = "container:Runner.xcodeproj">
           </BuildableReference>
        </BuildableProductRunnable>
     </LaunchAction>
     <ProfileAction
        buildConfiguration = "Release"
        shouldUseLaunchSchemeArgsEnv = "YES"
        savedToolIdentifier = ""
        useCustomWorkingDirectory = "NO"
        debugDocumentVersioning = "YES">
        <BuildableProductRunnable
           runnableDebuggingMode = "0">
           <BuildableReference
              BuildableIdentifier = "primary"
              BlueprintIdentifier = "97C146ED1CF9000F007C117D"
              BuildableName = "Runner.app"
              BlueprintName = "Runner"
              ReferencedContainer = "container:Runner.xcodeproj">
           </BuildableReference>
        </BuildableProductRunnable>
     </ProfileAction>
     <AnalyzeAction
        buildConfiguration = "Debug">
     </AnalyzeAction>
     <ArchiveAction
        buildConfiguration = "Release"
        revealArchiveInOrganizer = "YES">
     </ArchiveAction>
  </Scheme>
  XML
  
  # Write the scheme to both locations
  File.write(project_scheme_path, scheme_content)
  puts "✅ Created new Runner scheme in project: #{project_scheme_path}"
  
  File.write(workspace_scheme_path, scheme_content)
  puts "✅ Created new Runner scheme in workspace: #{workspace_scheme_path}"
end

# Create a basic contents.xcworkspacedata file if it doesn't exist
workspace_data_path = File.join(workspace_dir, 'contents.xcworkspacedata')
unless File.exist?(workspace_data_path)
  workspace_data_content = <<~XML
  <?xml version="1.0" encoding="UTF-8"?>
  <Workspace
     version = "1.0">
     <FileRef
        location = "group:Runner.xcodeproj">
     </FileRef>
     <FileRef
        location = "group:Pods/Pods.xcodeproj">
     </FileRef>
  </Workspace>
  XML
  
  File.write(workspace_data_path, workspace_data_content)
  puts "✅ Created contents.xcworkspacedata in workspace"
end

puts "🎉 Runner scheme fix completed!" 