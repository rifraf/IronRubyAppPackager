
module MSBuildHelper

  def self.find_msbuild
    msbuild = "c:\\windows\\Microsoft.NET\\Framework\\v2.0.50727\\msbuild.exe"
    msbuild = nil unless File.exists?(msbuild)
    unless msbuild
      msbuild = "c:\\winnt\\Microsoft.NET\\Framework\\v2.0.50727\\msbuild.exe"
      msbuild = nil unless File.exists?(msbuild)
      unless msbuild
        msbuild = 'msbuild'
      end
    end
    begin
      `#{msbuild} /version`
    rescue
      # IronRuby 1.0 comes here if msbuild not found
      puts "MSBuild was not found. Please add it to the path."
      exit(2)
    end
    if ($?.exitstatus > 0)
      puts "MSBuild was not found. Please add it to the path."
      exit(1)
    end
    msbuild
  end

  def self.build(image_folder, project)
    Dir.chdir(image_folder) do
      puts `#{self.find_msbuild} #{File.basename(project, '.rb')}.csproj`
    end
  end
end
