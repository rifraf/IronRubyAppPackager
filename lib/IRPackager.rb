#
# Usage: ir IRPackager.rb <main>.rb [vendor_foldernames..]
#
$LOAD_PATH.unshift File.dirname(__FILE__)
require 'build_operations'

project, folders = IRPackager::find_project_and_folders(ARGV)
IRPackager::create_csproject('./_IRPackager_', project, folders)
