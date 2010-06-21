#
# Usage: ir IRPackager.rb <main>.rb [vendor_foldernames..]
#
DEFAULT_FOLDER = './_IRPackager_'
def ir_build_folder
  ENV['_IRPackager_'] || DEFAULT_FOLDER
end


$LOAD_PATH.unshift File.dirname(__FILE__)
require 'build_operations'

# What are we building?
project, folders = IRPackager::find_project_and_folders(ARGV)

# Create the project
IRPackager::create_csproject(ir_build_folder, project, folders)

# Build it!
IRPackager::build_csproject(ir_build_folder, project)