#
# Usage: ir IRPackager.rb <main>.rb [vendor_foldernames..]
#

#require 'pp'

# TEMP patches need moving
if defined?(SERFS)

  if File.exist?('/_SerfsDirInfo_')
    load '/_SerfsDirInfo_'
    p SerfsDirInfo

    class Dir

      class << self
        alias_method :irembedded_old_stat, :'[]'
        def [](*args)
          results = irembedded_old_stat(*args)
  #        results << local_glob(args,0)
  puts "+++++++ #{__LINE__}".magenta
          puts args
  puts "+++++++ #{__LINE__}".magenta
  #       puts SerfsInstance.ResourceNames
  puts "+++++++ #{__LINE__}".magenta
          results
        end

        alias_method :irembedded_old_glob, :glob
        def glob(*args)
          results = irembedded_old_glob(*args)
  puts "------- #{__LINE__}"
          puts args
  puts "------- #{__LINE__}"
          results
        end

      end
    end
  end

#  class SERFS::Serfs
#  end
end

$LOAD_PATH.unshift File.dirname(__FILE__)
require 'colour_support'

if ARGV.length == 0
  puts "No arguments supplied.\nArgs are: <progname>.rb [[cache_folder]]".red
  exit(1)
end

DEFAULT_FOLDER = './_IRPackager_'
def ir_build_folder
  ENV['_IRPackager_'] || DEFAULT_FOLDER
end


require 'build_operations'

# What are we building?
project, folders = IRPackager::find_project_and_folders(ARGV)

# Create the project
IRPackager::create_csproject(ir_build_folder, project, folders)

# Build it!
IRPackager::build_csproject(ir_build_folder, project)

# Dogfood
if defined?(Vendorize)
  Vendorize.add('Program.csproj')
  Vendorize.add('Program.cs')
  Vendorize.add('AssemblyInfo.cs')
  Vendorize.add('IREmbeddedApp.dll')
  Vendorize.add('Serfs.dll')
end
