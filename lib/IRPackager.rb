#
# Usage: ir IRPackager.rb <main>.rb [vendor_foldernames..]
#
$LOAD_PATH.unshift File.dirname(__FILE__)
require 'build_operations'

# What are we building?
project, folders = IRPackager::find_project_and_folders(ARGV)

# Create the project
IRPackager::create_csproject('./_IRPackager_', project, folders)

# Build it!
IRPackager::build_csproject('./_IRPackager_', project)