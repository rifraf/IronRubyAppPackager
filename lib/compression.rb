require 'zlib'

module Compress
  # GZip a file in-place
  # Won't re-zip
  def self.in_place_compress_file(file)
    content = File.open(file,'rb') {|h| h.read }
    unless (content[0] == 31) && (content[1] == 139)
      Zlib::GzipWriter.open(file) { |gz| gz.write content }
    end
  end

  def self.in_place(dir)
    Dir[File.join(dir, '**')].each {|f| in_place_compress_file(f) unless File.directory?(f) }
  end

end