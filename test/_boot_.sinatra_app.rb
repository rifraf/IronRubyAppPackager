if defined?(Vendorize)
  #-----------------------------------------
  # This code only runs when running with
  # Vendorize in place, not when just running
  # with vendorized files
  #-----------------------------------------
  puts "VENDORIZING - running #{__FILE__}"
end

unless defined?(Vendorize)
  #-----------------------------------------
  # This code only runs when running 
  # with vendorized files
  #-----------------------------------------
  puts "Booting with #{__FILE__}"

  module Kernel
    # With an IronRuby embedded app 'z.rb', IR will sometimes
    # put a full path of the form c:/x/y/z.rb in the
    # caller list. Sinatra doesn't see z.rb as the main
    # app in that case, so doesn't start. This patch
    # solves the issue. It has to come before the
    # require sinatra
    alias ir_sinatra_old_caller caller
    def caller(num = 0)
      re_main = Regexp.new(".*#{$0}:(\\d+.*)")
      re_thisfile = Regexp.new("^#{__FILE__}:")
      callers = ir_sinatra_old_caller(num)
      callers.reject{|f| f =~ re_thisfile}.map{|f| f.gsub(re_main, $0 + ':\1')}
    end
  end
end

# Fix for IronRuby 1.0 running Sinatra 'straight'
# See http://ironruby.codeplex.com/workitem/3895 and
# http://gist.github.com/397707#file_sinatra_static_file_patch.rb.
module Sinatra
  module Helpers
    class WorkingStaticFile
      attr_accessor :file

      def initialize(path, mode)
        self.file = File.open(path, mode)
      end

      def to_path
        return file.path
      end

      def each
        file.rewind
        while buf = file.read(8192)
          yield buf
        end
      end
    end

    class StaticFile < File
      def self.open(path, mode)
        WorkingStaticFile.new(path, mode)
      end
    end
  end
end
