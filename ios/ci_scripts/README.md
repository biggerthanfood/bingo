# Xcode Cloud CI Scripts

This directory contains scripts that run as part of the Xcode Cloud CI/CD process.

## Scripts

### ci_post_clone.rb

This script is automatically executed by Xcode Cloud after cloning the repository. It performs the following tasks:

1. Downloads and installs Flutter SDK version 3.7.10 in the CI environment
2. Sets up Flutter environment variables
3. Generates the necessary Flutter configuration files
4. Runs `flutter pub get` to download dependencies
5. Navigates to the iOS directory
6. Disables User Script Sandboxing in the Xcode project
7. Installs CocoaPods dependencies with verbose output
8. Patches the CocoaPods framework scripts to fix the `readlink` issue that causes the "Command PhaseScriptExecution failed with a nonzero exit code" error
9. Verifies executable permissions on all script files

## How It Works

The script addresses several common issues with Flutter apps in Xcode Cloud:

1. **Flutter SDK Installation**: Installs a specific version (3.7.10) of Flutter, recommended for Xcode compatibility.

2. **User Script Sandboxing**: Disables the User Script Sandboxing setting in Xcode's build settings, which can cause script execution failures.

3. **CocoaPods Framework Scripts**: Fixes the known issue with CocoaPods and Xcode Cloud where the `readlink` command behaves differently in the Xcode Cloud environment.

The script:
- Clones the Flutter repository and checks out the specific version (3.7.10)
- Sets up environment variables needed by Flutter
- Creates/updates the Flutter configuration files
- Disables User Script Sandboxing in the Xcode project
- Uses improved regular expressions to find and fix problematic lines in the CocoaPods-generated framework scripts
- Adds error redirection and additional fallback handling for readlink commands
- Makes all script files executable with verified permissions

## Configuration

You can configure the Flutter version by changing these variables at the top of the script:

```ruby
# Set Flutter version - using 3.7.10+ as recommended for Xcode compatibility
FLUTTER_VERSION = "3.7.10"
FLUTTER_CHANNEL = "stable"
```

## Troubleshooting

If you're still experiencing build issues in Xcode Cloud:

1. Check the Xcode Cloud build logs for specific error messages
2. Look for errors in the Flutter installation or CocoaPods setup steps
3. Try cleaning Xcode Cloud caches and rebuilding
4. Ensure all script files have proper executable permissions
5. Verify that User Script Sandboxing is disabled for all build configurations
6. Check the readlink command availability and behavior in the CI environment
7. Try increasing the timeout for script execution in Xcode Cloud settings

## References

- [CocoaPods Issue #10229](https://github.com/CocoaPods/CocoaPods/issues/10229)
- [Xcode Cloud Documentation](https://developer.apple.com/documentation/xcode/xcode-cloud)
- [Flutter Documentation](https://flutter.dev/docs)
- [Flutter GitHub Issue #126014](https://github.com/flutter/flutter/issues/126014) - Related to Xcode build issues 