# Xcode Cloud CI Scripts

This directory contains scripts that run as part of the Xcode Cloud CI/CD process.

## Scripts

### ci_post_clone.rb

This script is automatically executed by Xcode Cloud after cloning the repository. It performs the following tasks:

1. Downloads and installs Flutter SDK version 3.7.12 in the CI environment
2. Sets up Flutter environment variables
3. Generates the necessary Flutter configuration files
4. Runs `flutter pub get` to download dependencies
5. Navigates to the iOS directory
6. Disables User Script Sandboxing in the Xcode project
7. Installs CocoaPods dependencies with verbose output
8. Patches the CocoaPods framework scripts to fix the `readlink` issue that causes the "Command PhaseScriptExecution failed with a nonzero exit code" error
9. Verifies executable permissions on all script files

### pre_archive.rb

This script is designed to fix the hardcoded Flutter path issue that causes "Command PhaseScriptExecution failed with a nonzero exit code" errors in Xcode Cloud. It:

1. Searches for build script files in derived data directory
2. Identifies scripts containing hardcoded paths to your local Flutter installation
3. Replaces these scripts with a robust version that uses the FLUTTER_ROOT environment variable
4. Includes fallback mechanisms to ensure the build can proceed even if Flutter isn't found

### xcode_hook.rb

This script provides a more direct fix for the hardcoded Flutter path issue. It:

1. Creates an emergency `xcode_backend.sh` script in the CI workspace
2. Patches all Xcode project files to use this emergency script instead of the hardcoded path
3. Calls the pre_archive script to patch any generated script files
4. Ensures that builds can proceed even in environments where Flutter might not be correctly set up

## How to Use the Fix for Hardcoded Flutter Paths

To fix the "Command PhaseScriptExecution failed with a nonzero exit code" error with the specific error message:

```
/bin/sh: /Users/username/path/to/flutter/packages/flutter_tools/bin/xcode_backend.sh: No such file or directory
```

You need to:

1. Make sure the pre_archive.rb and xcode_hook.rb scripts are executable:
   ```
   chmod +x ios/ci_scripts/pre_archive.rb
   chmod +x ios/ci_scripts/xcode_hook.rb
   ```

2. Add a pre-archive build phase to your Xcode project:
   - Open your iOS project in Xcode
   - Select the Runner target
   - Go to "Build Phases" tab
   - Click "+" at the top and select "New Run Script Phase"
   - Name it "Run Flutter Path Fix"
   - Add this script content:
     ```
     # Run the xcode_hook.rb script to fix Flutter paths
     cd "${SRCROOT}/../ios/ci_scripts"
     ruby xcode_hook.rb
     ```
   - Make sure this build phase is positioned BEFORE any Flutter script phases

3. Commit these changes to your repository

## How It Works

The scripts address several common issues with Flutter apps in Xcode Cloud:

1. **Flutter SDK Installation**: Installs a specific version (3.7.12) of Flutter, recommended for Xcode compatibility.

2. **User Script Sandboxing**: Disables the User Script Sandboxing setting in Xcode's build settings, which can cause script execution failures.

3. **CocoaPods Framework Scripts**: Fixes the known issue with CocoaPods and Xcode Cloud where the `readlink` command behaves differently in the Xcode Cloud environment.

4. **Hardcoded Flutter Paths**: Replaces hardcoded paths to your local Flutter installation with environment variables and emergency scripts that can run in the CI environment.

## Configuration

You can configure the Flutter version by changing these variables at the top of the ci_post_clone.rb script:

```ruby
# Set Flutter version - using 3.7.12 as recommended for Xcode compatibility
FLUTTER_VERSION = "3.7.12"
FLUTTER_CHANNEL = "stable"
```

## Troubleshooting

If you're still experiencing build issues in Xcode Cloud:

1. Check the Xcode Cloud build logs for specific error messages
2. Look for errors in the Flutter installation or CocoaPods setup steps
3. Try cleaning Xcode Cloud caches and rebuilding
4. Add debugging `echo` statements to the scripts to help identify where failures are occurring
5. Ensure all script files have proper executable permissions
6. Verify that User Script Sandboxing is disabled for all build configurations
7. Check if the specific script ID from your error message matches the one in pre_archive.rb
8. Consider adding the xcode_hook.rb script as a custom build phase in your Xcode project

## References

- [CocoaPods Issue #10229](https://github.com/CocoaPods/CocoaPods/issues/10229)
- [Xcode Cloud Documentation](https://developer.apple.com/documentation/xcode/xcode-cloud)
- [Flutter Documentation](https://flutter.dev/docs)
- [Flutter GitHub Issue #126014](https://github.com/flutter/flutter/issues/126014) - Related to Xcode build issues 