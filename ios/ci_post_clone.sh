#!/bin/bash

# ci_post_clone.sh
# This shell script runs after the repository is cloned in Xcode Cloud
# It sets up the Runner scheme directly in the format Xcode Cloud expects

echo "🔧 Setting up Xcode Cloud environment..."

# Print current directory and environment
echo "📂 Current directory: $(pwd)"
echo "🔍 CI Workspace: ${CI_WORKSPACE}"
echo "🔍 CI Primary Repository Directory: ${CI_PRIMARY_REPOSITORY_PATH}"

# Create the xcscheme in the exact location Xcode Cloud looks for it
XCODE_CLOUD_SCHEMES_DIR="${CI_WORKSPACE}/repository/ios/Runner.xcodeproj/xcshareddata/xcschemes"
mkdir -p "${XCODE_CLOUD_SCHEMES_DIR}"

echo "📝 Creating Runner scheme at: ${XCODE_CLOUD_SCHEMES_DIR}/Runner.xcscheme"

# Create the scheme file with all required build actions
cat > "${XCODE_CLOUD_SCHEMES_DIR}/Runner.xcscheme" << 'EOF'
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
EOF

echo "✅ Runner.xcscheme created successfully"

# Also create the scheme in the workspace
WORKSPACE_SCHEMES_DIR="${CI_WORKSPACE}/repository/ios/Runner.xcworkspace/xcshareddata/xcschemes"
mkdir -p "${WORKSPACE_SCHEMES_DIR}"
cp "${XCODE_CLOUD_SCHEMES_DIR}/Runner.xcscheme" "${WORKSPACE_SCHEMES_DIR}/Runner.xcscheme"

echo "✅ Copied Runner scheme to workspace at: ${WORKSPACE_SCHEMES_DIR}/Runner.xcscheme"

# Create workspace datamodel file
WORKSPACE_DATA_PATH="${CI_WORKSPACE}/repository/ios/Runner.xcworkspace/contents.xcworkspacedata"
cat > "${WORKSPACE_DATA_PATH}" << 'EOF'
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
EOF

echo "✅ contents.xcworkspacedata created"

# Create workspace check metadata
WORKSPACE_CHECKS="${CI_WORKSPACE}/repository/ios/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist"
mkdir -p "$(dirname "${WORKSPACE_CHECKS}")"
cat > "${WORKSPACE_CHECKS}" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>IDEDidComputeMac32BitWarning</key>
    <true/>
</dict>
</plist>
EOF

echo "✅ Workspace metadata created"

# Ensure Xcode knows the schemes exist
echo "Recreating Xcode project schemes list..."
if [ -f "${CI_WORKSPACE}/repository/ios/Runner.xcodeproj/xcuserdata/xcode.xcuserdatad/xcschemes/xcschememanagement.plist" ]; then
  rm -f "${CI_WORKSPACE}/repository/ios/Runner.xcodeproj/xcuserdata/xcode.xcuserdatad/xcschemes/xcschememanagement.plist"
fi

mkdir -p "${CI_WORKSPACE}/repository/ios/Runner.xcodeproj/xcuserdata/xcode.xcuserdatad/xcschemes"

cat > "${CI_WORKSPACE}/repository/ios/Runner.xcodeproj/xcuserdata/xcode.xcuserdatad/xcschemes/xcschememanagement.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>SchemeUserState</key>
    <dict>
        <key>Runner.xcscheme_^#shared#^_</key>
        <dict>
            <key>orderHint</key>
            <integer>0</integer>
        </dict>
    </dict>
    <key>SuppressBuildableAutocreation</key>
    <dict>
        <key>97C146ED1CF9000F007C117D</key>
        <dict>
            <key>primary</key>
            <true/>
        </dict>
    </dict>
</dict>
</plist>
EOF

echo "✅ xcschememanagement.plist created"

# Also set executable permissions on all scripts in the ci_scripts directory
SCRIPTS_DIR="${CI_WORKSPACE}/repository/ios/ci_scripts"
if [ -d "${SCRIPTS_DIR}" ]; then
  echo "Setting executable permissions for all scripts in ${SCRIPTS_DIR}"
  chmod -R +x "${SCRIPTS_DIR}"
fi

# Run Ruby script for further configuration if it exists
RUBY_SCRIPT="${CI_WORKSPACE}/repository/ios/ci_scripts/ci_post_clone.rb"
if [ -f "${RUBY_SCRIPT}" ]; then
  echo "Running Ruby post-clone script: ${RUBY_SCRIPT}"
  ruby "${RUBY_SCRIPT}"
fi

echo "🎉 Post-clone script completed successfully!" 