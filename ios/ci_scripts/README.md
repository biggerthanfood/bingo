# Xcode Cloud CI Scripts

This directory contains scripts that run as part of the Xcode Cloud CI/CD process.

## Scripts

### ci_post_clone.rb

This script is automatically executed by Xcode Cloud after cloning the repository. It performs the following tasks:

1. Navigates to the iOS directory
2. Installs CocoaPods dependencies
3. Patches the CocoaPods framework scripts to fix the `readlink` issue that causes the "Command PhaseScriptExecution failed with a nonzero exit code" error

## How It Works

The script fixes a known issue with CocoaPods and Xcode Cloud where the `readlink` command behaves differently in the Xcode Cloud environment compared to local development machines.

The script:
- Uses regular expressions to find problematic lines in the CocoaPods-generated framework scripts
- Adds fallback code to handle cases where symlinks might not be correctly resolved
- Makes the script executable

## Troubleshooting

If you're still experiencing build issues in Xcode Cloud:

1. Check the Xcode Cloud build logs to see if the post-clone script is being executed
2. Ensure that the Ruby script has executable permissions
3. Try modifying the regular expressions in the script to match the exact patterns in your generated framework scripts

## References

- [CocoaPods Issue #10229](https://github.com/CocoaPods/CocoaPods/issues/10229)
- [Xcode Cloud Documentation](https://developer.apple.com/documentation/xcode/xcode-cloud) 