#
# Support for merging a build project
#
module ILMergeHelper

  def self.find_ilmerge
    ilmerge = "C:\\Program Files\\Microsoft\\ILMerge\\ILMerge.exe"
    ilmerge = nil unless File.exists?(ilmerge)
    unless ilmerge
      ilmerge = 'ilmerge'
    end
    begin
      `#{ilmerge} /?`
    rescue
      ilmerge = nil
    end
    if ($?.exitstatus > 0)
      ilmerge = nil
    end
    unless ilmerge
      puts "ilmerge was not found. See http://research.microsoft.com/en-us/people/mbarnett/ILMerge.aspx."
      puts "Using ilmerge results in a single .exe file without needing support DLLs"
    end
    ilmerge
  end

  def self.build(image_folder, project)
    ilmerge = self.find_ilmerge
    return false unless ilmerge
    project_name = File.basename(project, '.rb')
    puts `#{ilmerge} #{image_folder}\\#{project_name}.exe /out:#{project_name}.exe #{image_folder}\\IREmbeddedApp.dll #{image_folder}\\Serfs.dll /ndebug`
    true
  end
end
