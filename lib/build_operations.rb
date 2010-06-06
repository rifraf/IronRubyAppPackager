module IRPackager
  require 'fileutils'
  require 'date'

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

    clone_build_support(image_folder)

    app_dir       = clone_source_files(image_folder, project, folders)
    assembly_info = create_assemblyinfo(image_folder, project_name)
    program_file  = create_program_cs(image_folder, project_name, app_dir, folders)
    csproj_file   = create_csproj(image_folder, project_name, app_dir, folders)
    
  end

  def self.clone_build_support(image_folder)
    Dir[File.join(File.dirname(__FILE__), '*.dll')].each do |file|
      FileUtils.cp file, image_folder, :verbose => true
    end
  end

  def self.clone_source_files(image_folder, project, folders)
    app_dir  = File.join(image_folder, 'App')
    Dir.mkdir(app_dir) unless File.exists?(app_dir)
    FileUtils.copy(project, app_dir)
    folders.each do |folder|
      FileUtils.cp_r folder, File.join(app_dir, folder), :verbose => true
    end
    return app_dir
  end

  # Creates Properties/AssemblyInfo.cs unless it exists
  def self.create_assemblyinfo(image_folder, project_name)
    destdir  = File.join(image_folder, 'Properties')
    destfile = File.join(destdir, 'AssemblyInfo.cs')
    unless File.exists?(destfile)
      Dir.mkdir destdir unless File.exists? destdir
      source_info = File.join(File.dirname(__FILE__), 'AssemblyInfo.cs')
      FileUtils.cp source_info, destdir, :verbose => true
      assemby_info = File.read(destfile)
      assemby_info.gsub! /PROJECTNAME/, project_name
      assemby_info.gsub! /YEAR/, Date.today.year.to_s
      File.open(destfile, 'wb') {|f| f.write assemby_info}
    end
    return destfile
  end

  # Creates <project>.cs unless it exists
  def self.create_program_cs(image_folder, project_name, app_dir, folders)
    destdir  = image_folder
    destfile = File.join(destdir, "#{project_name}.cs")
    unless File.exists?(destfile)
      source = File.join(File.dirname(__FILE__), 'Program.cs')
      FileUtils.cp source, destfile, :verbose => true
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
    ret = "er.Mount(\"#{app_root}\")"
    folders.each {|folder| ret << ".Mount(@\"#{app_root}\\\\#{folder}\")"}
    ret << ';'
    puts ret
    return ret
  end

  def self.create_csproj(image_folder, project_name, app_dir, folders)
    destdir  = image_folder
    destfile = File.join(destdir, "#{project_name}.csproj")
    unless File.exists?(destfile)
      source = File.join(File.dirname(__FILE__), 'Program.csproj')
      FileUtils.cp source, destfile, :verbose => true
      source_code = File.read(destfile)
      source_code.gsub! /PROJECTNAME/, project_name
      source_code.gsub! /YEAR/, Date.today.year.to_s
      File.open(destfile, 'wb') {|f| f.write source_code}
    end
    return destfile
  end
end
