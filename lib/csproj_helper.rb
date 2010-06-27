#
# Code for working with csproj files
#
require "rexml/document"
include REXML

#
# Make sure all resource files are embedded and non-copy
#
def clean_up_csproj_resources(doc, app_dir)

  app_root = File.basename(app_dir)

  # Get all itemgroup elements that are not embedded
  non_embedded_files = XPath.match( doc, "//ItemGroup/None") + XPath.match( doc, "//ItemGroup/Content") + XPath.match( doc, "//ItemGroup/Compile")
  # Select the ones that are resources
  non_embedded_resources = non_embedded_files.select {|e| (e.attributes['Include'] || '') =~ /^#{app_root}\\/}
  # Change them to embedded
  non_embedded_resources.each {|element|
    puts "Changing #{element.name} to EmbeddedResource: #{element.attributes['Include']}"
    element.name = 'EmbeddedResource'
  }

  # Get all itemgroup elements that are embedded
  embedded_files = XPath.match( doc, "//ItemGroup/EmbeddedResource")
  # Select the ones that are resources
  embedded_resources = embedded_files.select {|e| (e.attributes['Include'] || '') =~ /^#{app_root}\\/}
  embedded_resources.each {|element|
    if element.delete_element('CopyToOutputDirectory')
      puts "Removed 'CopyToOutputDirectory' for #{element.attributes['Include']}"
    end
  }
end

def convert_unicode(str)
  str.gsub(/\%(\d+)/) {
    case $1.to_i
    when 28 then '('
    when 29 then ')'
    else $1
    end
  }
end

#
# Are all resources in the project?
#
def check_all_resources_are_in_csproj(doc, app_dir)
  app_root = File.basename(app_dir)
  ignored_files = []
  if File.exist?('ignored_resources.txt')
    ignored_files = IO.readlines('ignored_resources.txt').collect {|f| f.chomp}
    ignored_files.compact!
  end
  embedded_resources = XPath.match( doc, "//ItemGroup/EmbeddedResource").select {|e| (e.attributes['Include'] || '') =~ /^#{app_root}\\/}
  resources_in_csproj = embedded_resources.collect {|element| convert_unicode(element.attributes['Include']) }
  resources_on_disk = {}
  holder = nil
  File.open(File.join(app_root, '_SerfsDirInfo_'),"w") do |dir_info_h|
    scan_files_on_disk(app_root, resources_on_disk) {|filename|
      unless resources_in_csproj.include?(filename)
        if ignored_files.include?(filename)
          puts "Ignoring: #{filename}"
        else
          unless holder
            holder = doc.root.add_element('ItemGroup')
          end
          puts "Adding: #{filename}"
          holder.add_element('EmbeddedResource', {'Include' => filename})
        end
      else
        #puts "OK #{f}"
      end
    }
    dir_info_h.puts resources_on_disk.inspect
  end

end


def scan_files_on_disk(dir, filemap, &blk)
  entries = Dir.entries(dir).delete_if {|e| (e =~ /^\./)}.map {|e| "#{dir}\\#{e}"}
  files = entries.select {|e| File.stat(e).file? }
  dirs  = entries.select {|e| File.stat(e).directory? }
  filemap[:files] = files.map {|full| full[/[^\\\/]*$/]} # names only
  filemap[:dirs] = {}
  files.each {|f| yield f }
  dirs.each {|d|
    dname = d[/[^\\\/]*$/]
    filemap[:dirs][dname] = {}
    scan_files_on_disk(d, filemap[:dirs][dname], &blk)
  }
end

#
# Do all the resources exist?
#
def check_all_csproj_resources_exist(doc, app_dir)
  app_root = File.basename(app_dir)

  embedded_resources = XPath.match( doc, "//ItemGroup/EmbeddedResource").select {|e| (e.attributes['Include'] || '') =~ /^#{app_root}\\/}
  embedded_resources.each {|element|
    file_name = convert_unicode(element.attributes['Include'])
    unless File.exists?(file_name)
      puts "MISSING: #{file_name}"
      element.parent.delete_element(element)
    end
  }
end

def sync_csproj(csproj_file, app_dir)
  # Read the project
  xml = File.read(csproj_file)
  doc = Document.new xml
  reference = doc.to_s
  Dir.chdir(File.dirname(csproj_file)) do
    clean_up_csproj_resources(doc, app_dir)
    check_all_resources_are_in_csproj(doc, app_dir)
    check_all_csproj_resources_exist(doc, app_dir)
  end

  # Update file?
  current = doc.to_s
  if current != reference
    File.open(csproj_file, "w") do |f|
      f.print current
      puts "Updated #{csproj_file}"
    end
  else
    puts "Checked #{csproj_file}"
  end
end
