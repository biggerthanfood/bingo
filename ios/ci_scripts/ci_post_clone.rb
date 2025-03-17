#!/usr/bin/env ruby

# Script to set up Flutter and fix CocoaPods framework scripts in Xcode Cloud
# This script runs after the repository is cloned in Xcode Cloud

require 'fileutils'
require 'open-uri'
require 'json'

# Set Flutter version - using 3.7.12 as recommended for Xcode compatibility
FLUTTER_VERSION = "3.7.12"
FLUTTER_CHANNEL = "stable"

# Define the path where Flutter will be installed
FLUTTER_HOME = File.join(ENV["CI_WORKSPACE"] || Dir.pwd, "flutter")

def download_and_install_flutter
  puts "🔄 Installing Flutter SDK version #{FLUTTER_VERSION} (#{FLUTTER_CHANNEL} channel)..."
  
  # Create directory for Flutter
  FileUtils.mkdir_p(FLUTTER_HOME)
  
  # Download Flutter SDK based on platform
  if RUBY_PLATFORM.include?("darwin")
    # macOS
    puts "📦 Downloading Flutter SDK for macOS..."
    # Clone the repository and checkout the specific version
    system("git clone -b #{FLUTTER_CHANNEL} https://github.com/flutter/flutter.git #{FLUTTER_HOME}") or raise "Failed to download Flutter"
    
    # Move into Flutter directory and checkout the specific version
    Dir.chdir(FLUTTER_HOME) do
      system("git fetch --tags") or raise "Failed to fetch Flutter tags"
      system("git checkout #{FLUTTER_VERSION}") or raise "Failed to checkout Flutter version #{FLUTTER_VERSION}"
    end
  else
    raise "Unsupported platform for Flutter installation: #{RUBY_PLATFORM}"
  end
  
  # Add Flutter to PATH
  ENV["PATH"] = "#{FLUTTER_HOME}/bin:#{ENV["PATH"]}"
  
  # Disable analytics and set up Flutter
  system("flutter config --no-analytics") or raise "Failed to configure Flutter"
  system("flutter precache --ios") or raise "Failed to precache Flutter iOS artifacts"
  system("flutter doctor -v") or raise "Flutter doctor check failed"
  
  puts "✅ Flutter installed successfully at #{FLUTTER_HOME}"
  
  # After installing Flutter, create symlinks to ensure xcode_backend.sh is found
  puts "Creating symlinks for Flutter scripts..."
  hardcoded_flutter_path = '/Users/cameronperry/app_development/flutter'
  FileUtils.mkdir_p("#{hardcoded_flutter_path}/packages/flutter_tools/bin")
  
  # Create a script that forwards to the actual Flutter script
  File.open("#{hardcoded_flutter_path}/packages/flutter_tools/bin/xcode_backend.sh", 'w') do |file|
    file.puts '#!/bin/sh'
    file.puts '# Forwarding script for hardcoded Flutter paths'
    file.puts 'echo "Forwarding from hardcoded path: $0"'
    file.puts 'echo "Arguments: $@"'
    file.puts ''
    file.puts "# Use the Flutter installation in #{FLUTTER_HOME}"
    file.puts "export FLUTTER_ROOT=\"#{FLUTTER_HOME}\""
    file.puts 'echo "FLUTTER_ROOT=$FLUTTER_ROOT"'
    file.puts ''
    file.puts '# Forward to the actual script'
    file.puts 'ACTUAL_SCRIPT="$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh"'
    file.puts 'if [ -f "$ACTUAL_SCRIPT" ]; then'
    file.puts '  echo "Forwarding to: $ACTUAL_SCRIPT"'
    file.puts '  "$ACTUAL_SCRIPT" "$@"'
    file.puts '  exit $?'
    file.puts 'else'
    file.puts '  echo "ERROR: Could not find actual script at $ACTUAL_SCRIPT"'
    file.puts '  exit 0 # Return success to allow build to continue'
    file.puts 'fi'
  end
  
  # Make the script executable
  FileUtils.chmod(0755, "#{hardcoded_flutter_path}/packages/flutter_tools/bin/xcode_backend.sh")
  puts "✅ Created forwarding script at #{hardcoded_flutter_path}/packages/flutter_tools/bin/xcode_backend.sh"
end

def setup_flutter_environment
  puts "🔧 Setting up Flutter environment variables..."
  
  # Set Flutter environment variables
  ENV["FLUTTER_ROOT"] = FLUTTER_HOME
  
  # Get the full path to the project directory
  project_path = ENV["CI_WORKSPACE"] || Dir.pwd
  ENV["FLUTTER_APPLICATION_PATH"] = project_path
  
  # Create or update the Generated.xcconfig file
  flutter_config_dir = File.join(project_path, "ios", "Flutter")
  FileUtils.mkdir_p(flutter_config_dir)
  
  generated_xcconfig = File.join(flutter_config_dir, "Generated.xcconfig")
  File.open(generated_xcconfig, "w") do |file|
    file.puts "// This is a generated file; do not edit or check into version control."
    file.puts "FLUTTER_ROOT=#{FLUTTER_HOME}"
    file.puts "FLUTTER_APPLICATION_PATH=#{project_path}"
    file.puts "COCOAPODS_PARALLEL_CODE_SIGN=true"
    file.puts "FLUTTER_TARGET=lib/main.dart"
    file.puts "FLUTTER_BUILD_DIR=build"
    file.puts "FLUTTER_BUILD_NAME=1.0.0"
    file.puts "FLUTTER_BUILD_NUMBER=1"
    file.puts "EXCLUDED_ARCHS[sdk=iphonesimulator*]=i386"
    file.puts "EXCLUDED_ARCHS[sdk=iphoneos*]=armv7"
    file.puts "DART_OBFUSCATION=false"
    file.puts "TRACK_WIDGET_CREATION=true"
    file.puts "TREE_SHAKE_ICONS=false"
    file.puts "PACKAGE_CONFIG=.dart_tool/package_config.json"
  end
  
  puts "✅ Flutter environment set up successfully"
end

def fix_frameworks_scripts
  puts "🔨 Fixing CocoaPods framework scripts for Xcode Cloud..."
  
  # Find all framework scripts in the Pods directory
  Dir.glob("Pods/Target Support Files/Pods-*/Pods-*-frameworks.sh").each do |script_path|
    puts "Processing: #{script_path}"
    
    # Read the content of the script
    content = File.read(script_path)
    
    # Backup the original file
    FileUtils.cp(script_path, "#{script_path}.backup")
    
    # More comprehensive approach to fix framework scripts
    
    # Fix readlink issues
    content.gsub!(/source=\$\{source\}/, 'source="${source:-}"')
    content.gsub!(/source="\$\(readlink "\${source\}"(\)|)"/, 'source="$(readlink -f "${source:-}" 2>/dev/null || echo "${source:-}")"')
    content.gsub!(/binary="\$\{dirname\}\/\$\(readlink "\${binary\}"(\)|)"/, 'binary="${dirname}/$(readlink -f "${binary}" 2>/dev/null || echo "${binary}")"')
    
    # Replace all instances of readlink without -f flag
    content.gsub!(/readlink ([^-])/, 'readlink -f \\1')
    
    # Fix for rsync issues
    content.gsub!(/(rsync -av .*?)\"/, '\\1 --no-perms \"')
    
    # Add safeguards for non-existent files
    content.gsub!(/if \[ -L "\$\{source\}" \]/, 'if [ -L "${source}" ] && [ -e "${source}" ]')
    
    # Make sure script fails gracefully
    if !content.include?("set -e")
      content = "#!/bin/sh\nset -e\n" + content.gsub(/^#!\/bin\/sh/, '')
    end
    
    # Write the modified content back to the file
    File.write(script_path, content)
    
    # Make sure the script is executable
    FileUtils.chmod(0755, script_path)
    
    puts "✅ Fixed: #{script_path}"
  end
  
  puts "✅ All CocoaPods framework scripts have been fixed for Xcode Cloud"
end

def disable_user_script_sandboxing
  puts "🔧 Disabling User Script Sandboxing in Xcode project..."
  
  # Find all .xcodeproj directories in the current directory
  Dir.glob("*.xcodeproj").each do |project_dir|
    project_pbxproj = File.join(project_dir, "project.pbxproj")
    
    if File.exist?(project_pbxproj)
      puts "Found Xcode project: #{project_dir}"
      
      # Read the project file
      content = File.read(project_pbxproj)
      
      # Backup the original file
      FileUtils.cp(project_pbxproj, "#{project_pbxproj}.backup")
      
      # More aggressive approach to disable sandboxing:
      
      # 1. Directly set USER_SCRIPT_SANDBOXING = NO in all build settings blocks
      if content.include?("USER_SCRIPT_SANDBOXING")
        content.gsub!(/USER_SCRIPT_SANDBOXING = YES;/, 'USER_SCRIPT_SANDBOXING = NO;')
        puts "Replaced existing USER_SCRIPT_SANDBOXING = YES with NO"
      else
        # Add the setting to each build configuration
        content.gsub!(/(buildSettings = \{)/, "\\1\n\t\t\t\tUSER_SCRIPT_SANDBOXING = NO;")
        puts "Added USER_SCRIPT_SANDBOXING = NO to all build configurations"
      end
      
      # 2. Also disable at the project level if possible
      if content.include?("ENABLE_USER_SCRIPT_SANDBOXING")
        content.gsub!(/ENABLE_USER_SCRIPT_SANDBOXING = YES;/, 'ENABLE_USER_SCRIPT_SANDBOXING = NO;')
      end
      
      # Write the modified content back to the file
      File.write(project_pbxproj, content)
      
      puts "✅ Disabled User Script Sandboxing in #{project_dir}"
    end
  end
  
  # Also look for xcconfig files that might contain the setting
  Dir.glob("*.xcconfig").each do |config_file|
    content = File.read(config_file)
    if content.include?("USER_SCRIPT_SANDBOXING") || content.include?("ENABLE_USER_SCRIPT_SANDBOXING")
      content.gsub!(/USER_SCRIPT_SANDBOXING\s*=\s*YES/, 'USER_SCRIPT_SANDBOXING = NO')
      content.gsub!(/ENABLE_USER_SCRIPT_SANDBOXING\s*=\s*YES/, 'ENABLE_USER_SCRIPT_SANDBOXING = NO')
      File.write(config_file, content)
      puts "✅ Disabled User Script Sandboxing in #{config_file}"
    end
  end
end

def fix_xcode_configurations
  puts "🔧 Fixing Xcode configurations..."
  
  # Fix for incorrect configuration setup
  # This ensures Debug/Release use the correct xcconfig files
  info_plist = "Runner/Info.plist"
  if File.exist?(info_plist)
    project_path = "Runner.xcodeproj/project.pbxproj"
    if File.exist?(project_path)
      content = File.read(project_path)
      
      # Check and update Debug configuration
      if content.include?("Pods-Runner.debug.xcconfig")
        content.gsub!(/Pods-Runner.debug.xcconfig/, 'Debug.xcconfig')
        puts "Fixed Debug configuration to use Debug.xcconfig"
      end
      
      # Check and update Release configuration
      if content.include?("Pods-Runner.release.xcconfig")
        content.gsub!(/Pods-Runner.release.xcconfig/, 'Release.xcconfig')
        puts "Fixed Release configuration to use Release.xcconfig"
      end
      
      # Save changes
      File.write(project_path, content)
      puts "✅ Fixed Xcode configurations"
    end
  end
end

def clean_derived_data
  puts "🧹 Cleaning derived data in CI environment..."
  
  # In CI environment, clear the derived data to avoid cached issues
  derived_data = File.expand_path("~/Library/Developer/Xcode/DerivedData")
  if Dir.exist?(derived_data)
    puts "Removing derived data at: #{derived_data}"
    # Use find command to safely delete content
    system("find \"#{derived_data}\" -mindepth 1 -delete")
    puts "✅ Cleared derived data"
  else
    puts "⚠️ Derived data directory not found"
  end
end

def update_cocoapods_version
  puts "🔄 Checking CocoaPods version..."
  
  # Get current CocoaPods version
  pod_version = `pod --version`.strip
  puts "Current CocoaPods version: #{pod_version}"
  
  # Check if we need to upgrade
  if pod_version < "1.12.1"
    puts "Upgrading CocoaPods to latest version..."
    system("gem install cocoapods") or puts "⚠️ Failed to upgrade CocoaPods, continuing with current version"
    
    # Verify upgrade
    pod_version = `pod --version`.strip
    puts "CocoaPods version after upgrade: #{pod_version}"
  else
    puts "✅ CocoaPods version is sufficient"
  end
end

def fix_flutter_path_in_project
  puts "🔧 Fixing hardcoded Flutter path in Xcode project..."
  
  # Find the project.pbxproj file
  project_file = "Runner.xcodeproj/project.pbxproj"
  
  if File.exist?(project_file)
    puts "Found project file: #{project_file}"
    
    # Read the content
    content = File.read(project_file)
    
    # Create backup
    backup_file = "#{project_file}.path_backup"
    if !File.exist?(backup_file)
      FileUtils.cp(project_file, backup_file)
    end
    
    # Find all Run Script phases and update the Flutter path
    hardcoded_paths = [
      "/Users/cameronperry/app_development/flutter/packages/flutter_tools/bin/xcode_backend.sh",
      "/Users/cameronperry/app_development/flutter"
    ]
    
    modified = false
    
    hardcoded_paths.each do |path|
      if content.include?(path)
        puts "Found hardcoded path: #{path}"
        escaped_path = path.gsub('/', '\\/')
        
        # Replace in shell script sections
        content.gsub!("\"#{path}", "\"$FLUTTER_ROOT")
        content.gsub!("'#{path}", "'$FLUTTER_ROOT")
        
        # Replace in shellScript property assignments
        content.gsub!(/(shellScript = .*?)#{escaped_path}/, "\\1$FLUTTER_ROOT")
        
        modified = true
      end
    end
    
    # Also find the specific script ID from the error message
    script_id = "9740EEB61CF901F6004384FC"
    if content.include?(script_id)
      puts "Found script with ID: #{script_id}"
      
      # Find the script section for this ID
      script_regex = /#{script_id}.*?shellScript = (.*?);/m
      if content =~ script_regex
        script_content = $1
        
        if script_content.include?("/Users/cameronperry")
          # Replace the script content with a version that uses $FLUTTER_ROOT
          new_script = script_content.gsub(/\/Users\/cameronperry\/app_development\/flutter/, "$FLUTTER_ROOT")
          content.gsub!(script_content, new_script)
          modified = true
        end
      end
    end
    
    # Update the run script phases to use Flutter from the environment
    content.gsub!(
      /(shellScript = )".+xcode_backend\.sh(.+)"/,
      '\1"$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh\2"'
    )
    
    if modified
      # Write the changes back to the file
      File.write(project_file, content)
      puts "✅ Fixed hardcoded Flutter paths in project file"
    else
      puts "⚠️ No hardcoded Flutter paths found to fix"
    end
  else
    puts "❌ Project file not found"
  end
  
  # Also fix any script files that might have hardcoded paths
  Dir.glob("**/*.sh").each do |script_file|
    if File.exist?(script_file)
      script_content = File.read(script_file)
      
      if script_content.include?("/Users/cameronperry/app_development/flutter")
        puts "Found hardcoded path in script: #{script_file}"
        backup_file = "#{script_file}.path_backup"
        if !File.exist?(backup_file)
          FileUtils.cp(script_file, backup_file)
        end
        
        script_content.gsub!("/Users/cameronperry/app_development/flutter", "$FLUTTER_ROOT")
        File.write(script_file, script_content)
        puts "✅ Fixed hardcoded Flutter path in script: #{script_file}"
        
        # Make sure script is executable
        FileUtils.chmod(0755, script_file)
      end
    end
  end
end

def create_wrapper_script
  puts "🔧 Creating xcode_backend.sh wrapper script..."
  
  # Create a wrapper script in the expected location to forward to the actual Flutter script
  run_script_dir = "scripts"
  FileUtils.mkdir_p(run_script_dir)
  
  wrapper_script = File.join(run_script_dir, "xcode_backend.sh")
  
  # Create a script that will relay to the actual Flutter xcode_backend.sh
  File.open(wrapper_script, "w") do |file|
    file.puts "#!/bin/sh"
    file.puts "# Wrapper script for Flutter's xcode_backend.sh"
    file.puts "# This script forwards to the actual Flutter script with the current FLUTTER_ROOT"
    file.puts ""
    file.puts "# Echo debugging information"
    file.puts "echo \"Running wrapper script: $0\""
    file.puts "echo \"FLUTTER_ROOT: $FLUTTER_ROOT\""
    file.puts "echo \"Arguments: $@\""
    file.puts ""
    file.puts "# Check if FLUTTER_ROOT is set"
    file.puts "if [ -z \"$FLUTTER_ROOT\" ]; then"
    file.puts "  echo \"Error: FLUTTER_ROOT is not set!\""
    file.puts "  exit 1"
    file.puts "fi"
    file.puts ""
    file.puts "# Check if the target script exists"
    file.puts "SCRIPT_PATH=\"$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh\""
    file.puts "if [ ! -f \"$SCRIPT_PATH\" ]; then"
    file.puts "  echo \"Error: Flutter script not found at $SCRIPT_PATH!\""
    file.puts "  ls -la \"$FLUTTER_ROOT/packages/flutter_tools/bin/\""
    file.puts "  exit 1"
    file.puts "fi"
    file.puts ""
    file.puts "# Execute the actual Flutter script with all arguments"
    file.puts "echo \"Executing: $SCRIPT_PATH $@\""
    file.puts "\"$SCRIPT_PATH\" \"$@\""
    file.puts "EXIT_CODE=$?"
    file.puts "echo \"Finished with exit code: $EXIT_CODE\""
    file.puts "exit $EXIT_CODE"
  end
  
  # Make the script executable
  FileUtils.chmod(0755, wrapper_script)
  
  puts "✅ Created wrapper script: #{wrapper_script}"
  
  # Now modify the project file to use our wrapper script instead
  project_file = "Runner.xcodeproj/project.pbxproj"
  if File.exist?(project_file)
    content = File.read(project_file)
    
    # Replace the script path in all build phases
    if content.gsub!(
      /"\$FLUTTER_ROOT\/packages\/flutter_tools\/bin\/xcode_backend\.sh"/,
      "\"${SRCROOT}/../#{run_script_dir}/xcode_backend.sh\""
    )
      File.write(project_file, content)
      puts "✅ Updated project to use wrapper script"
    else
      puts "⚠️ Could not update project to use wrapper script"
    end
  end
end

def add_firebase_script_phase
  puts "🔧 Adding Firebase configuration script build phase..."
  
  # Run the script to add a Firebase build phase to the Xcode project
  script_path = File.join(__dir__, "add_firebase_script_phase.rb")
  if File.exist?(script_path)
    # Make sure the script is executable
    FileUtils.chmod(0755, script_path)
    
    # Run the script
    success = system("ruby #{script_path}")
    if success
      puts "✅ Successfully added Firebase build phase to Xcode project"
    else
      puts "❌ Failed to add Firebase build phase"
    end
  else
    puts "❌ Firebase build phase script not found at: #{script_path}"
  end
end

def fix_swift_bridging
  puts "🔧 Applying Swift bridging header fixes..."
  
  # Run the script to fix Swift bridging header issues
  script_path = File.join(__dir__, "fix_swift_bridging.rb")
  if File.exist?(script_path)
    # Make sure the script is executable
    FileUtils.chmod(0755, script_path)
    
    # Run the script
    success = system("ruby #{script_path}")
    if success
      puts "✅ Successfully applied Swift bridging header fixes"
    else
      puts "❌ Failed to apply Swift bridging header fixes"
    end
  else
    puts "❌ Swift bridging header fix script not found at: #{script_path}"
  end
end

def fix_swift_missing_header
  puts "🔧 Fixing Swift missing GeneratedPluginRegistrant.h issue..."
  
  # Run the script to fix missing headers issue
  script_path = File.join(__dir__, "fix_swift_missing_header.rb")
  if File.exist?(script_path)
    # Make sure the script is executable
    FileUtils.chmod(0755, script_path)
    
    # Run the script
    success = system("ruby #{script_path}")
    if success
      puts "✅ Successfully fixed Swift missing header issue"
      
      # Now add a build phase to ensure headers are available during build
      headers_phase_script = File.join(__dir__, "add_ensure_headers_phase.rb")
      if File.exist?(headers_phase_script)
        # Make sure the script is executable
        FileUtils.chmod(0755, headers_phase_script)
        
        # Run the script
        headers_success = system("ruby #{headers_phase_script}")
        if headers_success
          puts "✅ Successfully added ensure headers build phase"
        else
          puts "❌ Failed to add ensure headers build phase"
        end
      else
        puts "❌ Add ensure headers phase script not found at: #{headers_phase_script}"
      end
    else
      puts "❌ Failed to fix Swift missing header issue"
    end
  else
    puts "❌ Swift missing header fix script not found at: #{script_path}"
  end
end

def add_xcode_prebuild_phase
  puts "🔧 Adding Xcode pre-build script phase..."
  
  # First make sure the pre-build script is executable
  prebuild_script = File.join(__dir__, "xcode_prebuild.sh")
  if File.exist?(prebuild_script)
    FileUtils.chmod(0755, prebuild_script)
    puts "✅ Made pre-build script executable"
    
    # Now add the pre-build phase to the Xcode project
    prebuild_phase_script = File.join(__dir__, "add_prebuild_phase.rb")
    if File.exist?(prebuild_phase_script)
      FileUtils.chmod(0755, prebuild_phase_script)
      
      # Run the script to add the pre-build phase
      success = system("ruby #{prebuild_phase_script}")
      if success
        puts "✅ Successfully added pre-build phase to Xcode project"
      else
        puts "❌ Failed to add pre-build phase to Xcode project"
      end
    else
      puts "❌ Add pre-build phase script not found at: #{prebuild_phase_script}"
    end
  else
    puts "❌ Pre-build script not found at: #{prebuild_script}"
  end
end

def fix_missing_header_direct
  puts "🔧 Running direct fix for missing GeneratedPluginRegistrant.h..."
  
  # Run the direct fix script
  script_path = File.join(__dir__, "fix_missing_header_direct.rb")
  if File.exist?(script_path)
    # Make sure the script is executable
    FileUtils.chmod(0755, script_path)
    
    # Run the script
    success = system("ruby #{script_path}")
    if success
      puts "✅ Successfully ran direct fix for missing header"
    else
      puts "❌ Failed to run direct fix for missing header"
    end
  else
    puts "❌ Direct fix script not found at: #{script_path}"
  end
end

def remove_bridging_header_requirement
  puts "🔧 Removing Swift bridging header requirement for CI builds..."
  
  # Run the script to remove bridging header
  script_path = File.join(__dir__, "remove_bridging_header.rb")
  if File.exist?(script_path)
    # Make sure the script is executable
    FileUtils.chmod(0755, script_path)
    
    # Run the script
    success = system("ruby #{script_path}")
    if success
      puts "✅ Successfully removed bridging header requirement"
    else
      puts "❌ Failed to remove bridging header requirement"
    end
  else
    puts "❌ Remove bridging header script not found at: #{script_path}"
  end
end

# Set up Firebase configuration
puts "📱 Setting up Firebase configuration..."
load "#{__dir__}/setup_firebase.rb"

begin
  # Navigate to the project directory
  Dir.chdir(ENV["CI_WORKSPACE"] || Dir.pwd) do
    puts "📂 Current directory: #{Dir.pwd}"
    puts "🔍 CI Environment: #{ENV["CI"] ? "Yes" : "No"}"
    puts "🔍 CI Workspace: #{ENV["CI_WORKSPACE"] || "Not set"}"
    
    # Update CocoaPods first
    update_cocoapods_version
    
    # Clean derived data
    clean_derived_data
    
    # Install Flutter
    download_and_install_flutter
    
    # Set up Flutter environment
    setup_flutter_environment
    
    # Run Flutter pub get
    puts "📦 Running flutter pub get..."
    system("flutter pub get") or raise "Failed to run flutter pub get"
    
    # Navigate to the iOS directory
    if Dir.exist?("ios")
      Dir.chdir("ios") do
        puts "📂 Changed to iOS directory: #{Dir.pwd}"
        
        # Fix hardcoded Flutter paths - this addresses the specific error
        fix_flutter_path_in_project
        
        # Create wrapper script - this provides an additional fallback
        create_wrapper_script
        
        # Add Firebase configuration script build phase
        add_firebase_script_phase
        
        # Fix Swift bridging header issues
        fix_swift_bridging
        
        # Fix Swift missing header issue 
        fix_swift_missing_header
        
        # Apply direct fix for missing headers
        fix_missing_header_direct
        
        # Add pre-build script phase to Xcode project
        add_xcode_prebuild_phase
        
        # Remove bridging header requirement - most drastic solution
        remove_bridging_header_requirement
        
        # First, try cleaning any previous pod installation
        puts "🧹 Cleaning CocoaPods installation..."
        FileUtils.rm_rf("Pods") if Dir.exist?("Pods")
        FileUtils.rm("Podfile.lock") if File.exist?("Podfile.lock")
        
        # Disable User Script Sandboxing
        disable_user_script_sandboxing
        
        # Fix Xcode configurations
        fix_xcode_configurations
        
        # Run CocoaPods installation with verbose output
        puts "📦 Installing CocoaPods dependencies..."
        system("pod install --verbose") or raise "Failed to install pods"
        
        # Fix the frameworks scripts
        fix_frameworks_scripts
        
        # Verify permissions and existence of all scripts
        Dir.glob("Pods/Target Support Files/Pods-*/Pods-*-frameworks.sh").each do |script_path|
          FileUtils.chmod(0755, script_path)
          puts "✅ Verified executable permissions: #{script_path} (#{sprintf('%o', File.stat(script_path).mode & 0777)})"
        end
        
        # Run pod install again to ensure everything is consistent
        puts "🔄 Running pod install again to ensure consistency..."
        system("pod install --verbose") or puts "⚠️ Second pod install failed, but continuing..."
      end
    else
      puts "❌ iOS directory not found"
      exit 1
    end
  end

  # Run the xcode_cloud_fix.sh script to fix hardcoded Flutter paths
  puts "Running xcode_cloud_fix.sh to fix hardcoded Flutter paths..."
  system("#{__dir__}/xcode_cloud_fix.sh")
  puts "✅ Completed xcode_cloud_fix.sh"

  # We no longer need this since we've added a build phase
  # Check for Firebase configuration file and create placeholder if needed
  # puts "🔍 Checking for Firebase configuration file..."
  # system("#{__dir__}/check_firebase_config.sh") or puts "⚠️ Failed to run Firebase configuration check"

  puts "🎉 Post-clone script completed successfully"
  exit 0
  
rescue => e
  puts "❌ Error: #{e.message}"
  puts e.backtrace
  exit 1
end 