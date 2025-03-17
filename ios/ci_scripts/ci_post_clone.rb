#!/usr/bin/env ruby

# Script to fix CocoaPods framework scripts in Xcode Cloud
# This script runs after the repository is cloned in Xcode Cloud

require 'fileutils'

def fix_frameworks_scripts
  puts "🔨 Fixing CocoaPods framework scripts for Xcode Cloud..."
  
  # Find all framework scripts in the Pods directory
  Dir.glob("Pods/Target Support Files/Pods-*/Pods-*-frameworks.sh").each do |script_path|
    puts "Processing: #{script_path}"
    
    # Read the content of the script
    content = File.read(script_path)
    
    # Backup the original file
    FileUtils.cp(script_path, "#{script_path}.backup")
    
    # Fix the symlink resolution
    content.gsub!(/source=\$\{source\}/, 'source="${source:-}"')
    content.gsub!(/source="\$\(readlink "\${source\}"(\)|)"/, 'source="$(readlink -f "${source:-}" || echo "${source:-}")"')
    content.gsub!(/binary="\$\{dirname\}\/\$\(readlink "\${binary\}"(\)|)"/, 'binary="${dirname}/$(readlink -f "${binary}" || echo "${binary}")"')
    
    # Write the modified content back to the file
    File.write(script_path, content)
    
    # Make sure the script is executable
    FileUtils.chmod("+x", script_path)
    
    puts "✅ Fixed: #{script_path}"
  end
  
  puts "✅ All CocoaPods framework scripts have been fixed for Xcode Cloud"
end

# Navigate to the project directory
Dir.chdir(ENV["CI_WORKSPACE"] || Dir.pwd) do
  puts "📂 Current directory: #{Dir.pwd}"
  
  # Navigate to the iOS directory
  if Dir.exist?("ios")
    Dir.chdir("ios") do
      puts "📂 Changed to iOS directory: #{Dir.pwd}"
      
      # Run CocoaPods installation
      puts "📦 Installing CocoaPods dependencies..."
      system("pod install") or raise "Failed to install pods"
      
      # Fix the frameworks scripts
      fix_frameworks_scripts
    end
  else
    puts "❌ iOS directory not found"
    exit 1
  end
end

puts "🎉 Post-clone script completed successfully"
exit 0 