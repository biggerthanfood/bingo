# Xcode Cloud CI Scripts

This directory contains scripts that run as part of the Xcode Cloud CI/CD process.

## Scripts

### ci_post_clone.rb

This script is automatically executed by Xcode Cloud after cloning the repository. It performs the following tasks:

1. Downloads and installs Flutter SDK in the CI environment
2. Sets up Flutter environment variables
3. Generates the necessary Flutter configuration files
4. Runs `flutter pub get` to download dependencies
5. Navigates to the iOS directory
6. Installs CocoaPods dependencies
7. Patches the CocoaPods framework scripts to fix the `readlink` issue that causes the "Command PhaseScriptExecution failed with a nonzero exit code" error

## How It Works

The script addresses two main issues with Flutter apps in Xcode Cloud:

1. **Flutter SDK Installation**: Xcode Cloud doesn't come with Flutter pre-installed, so the script downloads and configures the Flutter SDK.

2. **CocoaPods Framework Scripts**: The script fixes a known issue with CocoaPods and Xcode Cloud where the `readlink` command behaves differently in the Xcode Cloud environment compared to local development machines.

The script:
- Clones the Flutter repository to get the SDK
- Sets up environment variables needed by Flutter
- Creates/updates the Flutter configuration files
- Uses regular expressions to find problematic lines in the CocoaPods-generated framework scripts
- Adds fallback code to handle cases where symlinks might not be correctly resolved
- Makes the script executable

## Configuration

You can configure the Flutter version by changing these variables at the top of the script:

```ruby
# Set Flutter version - you can adjust this as needed
FLUTTER_VERSION = "stable"
FLUTTER_CHANNEL = "stable"
```

## Troubleshooting

If you're still experiencing build issues in Xcode Cloud:

1. Check the Xcode Cloud build logs to see if the post-clone script is being executed
2. Ensure that the Ruby script has executable permissions
3. Look for errors in the Flutter installation or CocoaPods setup steps
4. Try modifying the regular expressions in the script to match the exact patterns in your generated framework scripts
5. Ensure the CI system has sufficient memory and disk space to download and install Flutter

## References

- [CocoaPods Issue #10229](https://github.com/CocoaPods/CocoaPods/issues/10229)
- [Xcode Cloud Documentation](https://developer.apple.com/documentation/xcode/xcode-cloud)
- [Flutter Documentation](https://flutter.dev/docs) 