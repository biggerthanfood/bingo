#!/usr/bin/env ruby

# fix_scheme_in_dev.rb
# This script copies the Runner scheme to the 'dev' branch since the error message specifically mentioned the dev branch

require 'fileutils'
require 'open3'

puts "🔧 Fixing Runner scheme for 'dev' branch..."

# Check if this is running in Xcode Cloud
is_ci = ENV["CI"] == "true" || !ENV["CI_WORKSPACE"].nil?
puts "Running in CI environment: #{is_ci ? 'Yes' : 'No'}"

# Get the current branch
stdout, stderr, status = Open3.capture3("git rev-parse --abbrev-ref HEAD")
current_branch = stdout.strip
puts "Current branch: #{current_branch}"

if is_ci
  # Create directories expected by Xcode Cloud
  schemes_dir = File.join(ENV["CI_WORKSPACE"] || Dir.pwd, "repository", "ios", "Runner.xcodeproj", "xcshareddata", "xcschemes")
  workspace_schemes_dir = File.join(ENV["CI_WORKSPACE"] || Dir.pwd, "repository", "ios", "Runner.xcworkspace", "xcshareddata", "xcschemes")
else
  # Use relative paths for local development
  schemes_dir = File.expand_path(File.join(__dir__, "..", "Runner.xcodeproj", "xcshareddata", "xcschemes"))
  workspace_schemes_dir = File.expand_path(File.join(__dir__, "..", "Runner.xcworkspace", "xcshareddata", "xcschemes")) 
end

FileUtils.mkdir_p(schemes_dir)
FileUtils.mkdir_p(workspace_schemes_dir)

puts "Project schemes directory: #{schemes_dir}"
puts "Workspace schemes directory: #{workspace_schemes_dir}"

# Create the scheme file
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

# Write the scheme file to both the project and workspace
project_scheme_path = File.join(schemes_dir, "Runner.xcscheme")
workspace_scheme_path = File.join(workspace_schemes_dir, "Runner.xcscheme")

File.write(project_scheme_path, scheme_content)
puts "✅ Created Runner scheme in project: #{project_scheme_path}"

File.write(workspace_scheme_path, scheme_content)
puts "✅ Created Runner scheme in workspace: #{workspace_scheme_path}"

# If not on dev branch, try to create and push the scheme to the dev branch
if current_branch != "dev" && !is_ci
  puts "Current branch is #{current_branch}, attempting to create/update Runner scheme in 'dev' branch..."
  
  # Store current branch to return to it later
  orig_branch = current_branch
  
  # Check if dev branch exists
  stdout, stderr, status = Open3.capture3("git branch --list dev")
  if stdout.strip.empty?
    puts "⚠️ 'dev' branch doesn't exist locally. Checking remote..."
    
    # Check if dev branch exists remotely
    stdout, stderr, status = Open3.capture3("git ls-remote --heads origin dev")
    if stdout.strip.empty?
      puts "⚠️ 'dev' branch doesn't exist remotely either. Creating new 'dev' branch..."
      system("git checkout -b dev") or puts "❌ Failed to create 'dev' branch"
    else
      puts "✅ 'dev' branch exists remotely. Checking out..."
      system("git checkout -b dev origin/dev") or puts "❌ Failed to checkout 'dev' branch"
    end
  else
    puts "✅ 'dev' branch exists locally. Checking out..."
    system("git checkout dev") or puts "❌ Failed to checkout 'dev' branch"
  end
  
  # Create the schemes directories in dev branch if needed
  FileUtils.mkdir_p(schemes_dir)
  FileUtils.mkdir_p(workspace_schemes_dir)
  
  # Write the scheme files in dev branch
  File.write(project_scheme_path, scheme_content)
  File.write(workspace_scheme_path, scheme_content)
  
  # Commit and push the changes
  puts "Committing scheme changes to 'dev' branch..."
  system("git add #{project_scheme_path} #{workspace_scheme_path}")
  system('git commit -m "Add Runner scheme to fix Xcode Cloud build"')
  
  puts "Pushing scheme changes to 'dev' branch..."
  system("git push origin dev")
  
  # Return to original branch
  puts "Returning to #{orig_branch} branch..."
  system("git checkout #{orig_branch}")
  
  puts "✅ Runner scheme has been added to 'dev' branch"
else
  puts "Already on 'dev' branch or running in CI - no branch switching needed"
end

puts "🎉 Runner scheme fix for 'dev' branch completed!" 