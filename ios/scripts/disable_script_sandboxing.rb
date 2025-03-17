#!/usr/bin/env ruby

require 'fileutils'

# Find all .xcodeproj directories
Dir.glob("ios/*.xcodeproj").each do |project_dir|
  project_pbxproj = File.join(project_dir, "project.pbxproj")
  
  if File.exist?(project_pbxproj)
    puts "Found Xcode project: #{project_dir}"
    
    # Read the project file
    content = File.read(project_pbxproj)
    
    # Backup the original file
    FileUtils.cp(project_pbxproj, "#{project_pbxproj}.backup")
    
    # Add USER_SCRIPT_SANDBOXING = NO to all build configurations
    if content.include?("USER_SCRIPT_SANDBOXING")
      # Replace existing setting
      content.gsub!(/USER_SCRIPT_SANDBOXING = YES;/, 'USER_SCRIPT_SANDBOXING = NO;')
      puts "Replaced existing USER_SCRIPT_SANDBOXING = YES with NO"
    else
      # Add the setting to each build configuration
      content.gsub!(/(buildSettings = \{)/, "\\1\n\t\t\t\tUSER_SCRIPT_SANDBOXING = NO;")
      puts "Added USER_SCRIPT_SANDBOXING = NO to all build configurations"
    end
    
    # Write the modified content back to the file
    File.write(project_pbxproj, content)
    
    puts "✅ Disabled User Script Sandboxing in #{project_dir}"
  end
end

if Dir.glob("ios/*.xcodeproj").empty?
  puts "❌ No Xcode project found in the ios directory"
end 