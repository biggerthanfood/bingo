#!/usr/bin/env ruby

require 'fileutils'

def fix_flutter_path_in_project
  puts "🔧 Fixing Flutter path in Xcode project..."
  
  # Find the project.pbxproj file
  project_file = "Runner.xcodeproj/project.pbxproj"
  
  if File.exist?(project_file)
    puts "Found project file: #{project_file}"
    
    # Read the content
    content = File.read(project_file)
    
    # Create backup
    FileUtils.cp(project_file, "#{project_file}.backup")
    
    # Find the hard-coded path to your local Flutter installation and replace it with a relative path
    local_flutter_path = "/Users/cameronperry/app_development/flutter"
    if content.include?(local_flutter_path)
      puts "Found hardcoded local Flutter path: #{local_flutter_path}"
      
      # Several approaches to fix the path
      
      # Option 1: Replace with $FLUTTER_ROOT (which is set in our CI script)
      content.gsub!("\"#{local_flutter_path}/packages/flutter_tools/bin/xcode_backend.sh\"", "\"$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh\"")
      
      # Option 2: Also fix for places that might have it with single quotes
      content.gsub!("'#{local_flutter_path}/packages/flutter_tools/bin/xcode_backend.sh'", "'$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh'")
      
      # Option 3: Fix for shellScript property that might have the full path
      content.gsub!(/(shellScript = ")#{local_flutter_path.gsub('/', '\/')}/, '\1$FLUTTER_ROOT')
      
      # Write the changes back
      File.write(project_file, content)
      puts "✅ Fixed hardcoded Flutter path in project file"
    else
      puts "⚠️ Local Flutter path not found in project file"
    end
  else
    puts "❌ Project file not found"
  end
  
  # Also check for any .sh files that might reference the hardcoded path
  Dir.glob("**/*.sh").each do |script_file|
    content = File.read(script_file)
    if content.include?("/Users/cameronperry/app_development/flutter")
      puts "Found hardcoded path in #{script_file}"
      FileUtils.cp(script_file, "#{script_file}.backup")
      
      content.gsub!("/Users/cameronperry/app_development/flutter", "$FLUTTER_ROOT")
      File.write(script_file, content)
      puts "✅ Fixed hardcoded Flutter path in #{script_file}"
    end
  end
end

# If run directly
if __FILE__ == $0
  fix_flutter_path_in_project
end 