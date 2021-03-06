module IRPackager
  require 'fileutils'
  require 'date'
  require 'msbuild_helper'
  require 'ilmerge_helper'

  # Expects first arg to be the name of the project (main.rb) and
  # any other args to be a list of folders to include. Defaults to
  # ['_Vendor_']
  def self.find_project_and_folders(args)
    project = args.shift
    folders = args.dup
    folders << '_Vendor_' if folders.length == 0
    [project, folders]
  end

  #
  # Create a build image including:
  # - the project .rb file
  # - folder contents
  # - a <project>.cs file
  # - a <project>.csproj file
  # - assembly info
  # - Serfs/IREmbeddedApp
  #
  def self.create_csproject(image_folder, project, folders)
    project_name = File.basename(project, ".rb")
    Dir.mkdir(image_folder) unless File.exists?(image_folder)

    create_assemblyinfo(image_folder, project_name)

    app_dir = clone_source_files(image_folder, project, folders)
    create_program_cs(image_folder, project_name, app_dir, folders)
    clone_build_support(image_folder)

    csproj_file   = create_csproj(image_folder, project_name)
    synchronize_csproj(csproj_file, app_dir)
    
  end

  def self.clone_build_support(image_folder)
    # TODO: support Dir[] in Serfs
    Dir[File.join(File.dirname(__FILE__), '*.dll')].each do |file|
puts "+++++++> #{file}".magenta
#      FileUtils.cp file, image_folder, :verbose => true
    end

puts "+++++++ #{File.join(File.dirname(__FILE__), 'Serfs.dll')}".magenta
FileUtils.cp File.join(File.dirname(__FILE__), 'Serfs.dll'), image_folder #, :verbose => true
FileUtils.cp File.join(File.dirname(__FILE__), 'IREmbeddedApp.dll'), image_folder #, :verbose => true
puts "+++++++ ".magenta
  end

  def self.clone_source_files(image_folder, project, folders)
    app_dir  = File.join(image_folder, 'App')
    Dir.mkdir(app_dir) unless File.exists?(app_dir)
    FileUtils.copy(project, app_dir)
    boot_file = '_boot_.' + project
    boot_cmd = '# Prevent rubygems from getting loaded
$" << \'rubygems.rb\' << \'rubygems\' unless ENV[\'_IRPACKAGER_KEEP_GEMS_\']
'
    boot_cmd << IO.read(boot_file) if File.exists?(boot_file)
    boot_dir = File.join(app_dir, 'EmbeddedRuby')
    Dir.mkdir(boot_dir) unless File.exists?(boot_dir)
    File.open(File.join(boot_dir, 'AppBoot.rb'),"w") {|h| h.puts boot_cmd}
    folders.each do |folder|
      FileUtils.cp_r(folder + '/.', File.expand_path(app_dir), :verbose => false) if File.exists?(folder)
    end
    require 'Compression'
    Compress.in_place(app_dir) unless ENV['_IRPACKAGER_NOZIP_']
    return app_dir
  end

  # Creates Properties/AssemblyInfo.cs unless it exists
  def self.create_assemblyinfo(image_folder, project_name)
    destdir  = File.join(image_folder, 'Properties')
    destfile = File.join(destdir, 'AssemblyInfo.cs')
    unless File.exists?(destfile)
      Dir.mkdir destdir unless File.exists? destdir
      source_info = File.join(File.dirname(__FILE__), 'AssemblyInfo.cs')
      FileUtils.cp source_info, destdir #, :verbose => true
      assembly_info = File.read(destfile)
      assembly_info.gsub! /PROJECTNAME/, project_name
      assembly_info.gsub! /YEAR/, Date.today.year.to_s
      File.open(destfile, 'wb') {|f| f.write assembly_info}
    end
    return destfile
  end

  # Creates <project>.cs unless it exists
  def self.create_program_cs(image_folder, project_name, app_dir, folders)
    destdir  = image_folder
    destfile = File.join(destdir, "#{project_name}.cs")
    unless File.exists?(destfile)
      source = File.join(File.dirname(__FILE__), 'Program.cs')
      FileUtils.cp source, destfile #, :verbose => true
      source_code = File.read(destfile)
      source_code.gsub! /PROJECTNAME/, project_name
      source_code.gsub! /YEAR/, Date.today.year.to_s
      source_code.gsub! /er.Mount\("App"\);/, mount_info(app_dir, folders)
      File.open(destfile, 'wb') {|f| f.write source_code}
    end
    return destfile
  end

  def self.mount_info(app_dir, folders)
    app_root = File.basename(app_dir)
#    full_path_to_app = File.expand_path(app_dir)

    ret = "er.Mount(\"#{app_root}\")"
#    folders.each do |folder|
#      full_path = File.expand_path(File.join(app_dir,folder))
#      subfolder = full_path[(full_path_to_app.length + 1)..-1]
#      ret << ".Mount(@\"#{app_root}\\\\#{subfolder}\")"
#    end
    ret << ';'
#    puts ret
    return ret
  end

  def self.create_csproj(image_folder, project_name)
    destdir  = image_folder
    destfile = File.join(destdir, "#{project_name}.csproj")
    unless File.exists?(destfile)
      source = File.join(File.dirname(__FILE__), 'Program.csproj')
      FileUtils.cp source, destfile #, :verbose => true
      source_code = File.read(destfile)
      source_code.gsub! /PROJECTNAME/, project_name
      source_code.gsub! /YEAR/, Date.today.year.to_s
      File.open(destfile, 'wb') {|f| f.write source_code}
    end
    return destfile
  end

  def self.synchronize_csproj(csproj_file, app_dir)
    require 'csproj_helper'
    sync_csproj(csproj_file, app_dir)
  end

  def self.build_csproject(image_folder, project)
    location = MSBuildHelper.build(image_folder, project)
    if ILMergeHelper.build(location, project)
      puts "*** Created #{File.basename(project,'.rb')}.exe (single file) ***".green
    else
      puts "*** Created #{location}\\#{File.basename(project,'.rb')}.exe (plus 2 support DLLs) ***".green
    end
  end
  
end
