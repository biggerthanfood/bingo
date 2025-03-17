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

# Create xcshareddata/xcschemes directories in project if they don't exist
project_schemes_dir = File.join(project_dir, 'xcshareddata', 'xcschemes')
FileUtils.mkdir_p(project_schemes_dir)
puts "✅ Created or verified project schemes directory: #{project_schemes_dir}"

# Define the scheme file paths
project_scheme_path = File.join(project_schemes_dir, 'Runner.xcscheme')
workspace_scheme_path = File.join(workspace_schemes_dir, 'Runner.xcscheme')

# Create a fully configured Runner scheme file
scheme_content = <<~XML
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1400"
   version = "1.7">
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
      <MacroExpansion>
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "97C146ED1CF9000F007C117D"
            BuildableName = "Runner.app"
            BlueprintName = "Runner"
            ReferencedContainer = "container:Runner.xcodeproj">
         </BuildableReference>
      </MacroExpansion>
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
      buildConfiguration = "Profile"
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
   </ArchiveAction>
</Scheme>
XML

# Write the scheme file to both locations
File.write(project_scheme_path, scheme_content)
puts "✅ Created or updated Runner scheme in project: #{project_scheme_path}"

File.write(workspace_scheme_path, scheme_content)
puts "✅ Created or updated Runner scheme in workspace: #{workspace_scheme_path}"

# Create a basic contents.xcworkspacedata file if it doesn't exist
workspace_data_path = File.join(workspace_dir, 'contents.xcworkspacedata')
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
puts "✅ Created or updated contents.xcworkspacedata in workspace"

# Ensure that the scheme is visible in Xcode Cloud by creating metadata
metadata_dir = File.join(workspace_dir, 'xcshareddata', 'IDEWorkspaceChecks.plist')
FileUtils.mkdir_p(File.dirname(metadata_dir))
metadata_content = <<~XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>IDEDidComputeMac32BitWarning</key>
	<true/>
</dict>
</plist>
XML

File.write(metadata_dir, metadata_content)
puts "✅ Created IDE workspace checks metadata"

puts "🎉 Runner scheme fix completed! The scheme should now be properly configured for all build actions." 