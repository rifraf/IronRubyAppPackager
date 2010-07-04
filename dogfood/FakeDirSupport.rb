#
# Supports one or more parallel directories within 'Dir'.
# The parallel directories are described in a hash that
# looks a bit like this:
# {
#  :files=>["main", "optparse.rb"],
#  :dirs=> {
#   "EmbeddedRuby"=>{:files=>["AppBoot.rb"], :dirs=>{}},
#   "test"=>{
#     :files=>["unit.rb"],
#     :dirs=>{"unit"=> {
#       :files=>[...]
#
# Apis supported:
#n  Dir[ array ] => array
#n  Dir[ string [, string ...] ] => array
#  Dir.chdir( [ string] ) => 0
#  Dir.chdir( [ string] ) {| path | block } => anObject
#  Dir.entries( dirname ) => array
#  Dir.foreach( dirname ) {| filename | block } => nil
#  Dir.getwd => string
#  Dir.pwd => string
#n  Dir.glob( pattern, [flags] ) => array
#n  Dir.glob( pattern, [flags] ) {| filename | block } => nil
#n  Dir.new( string ) => aDir
#n  Dir.open( string ) => aDir
#n  Dir.open( string ) {| aDir | block } => anObject
#
# Unsupported:
#  Dir.chroot( string ) => 0
#  Dir.delete( string ) => 0
#  Dir.rmdir( string ) => 0
#  Dir.unlink( string ) => 0
#  Dir.mkdir( string [, integer] ) => 0
#
class Dir
  @@fakes = {}
  @@current_fake = nil

  class << self
    # Any number of differently named fakes can be declared
    def add_fake(fake_name, dir_info)
      @@current_fake = @@fakes[fake_name] = {:filesystem => fake_name}.merge(dir_info)
      @@current_fake[:cwd] = @@current_fake
      create_folder_linkage(@@current_fake)
      return @@current_fake
    end

    # This will select one of the declared fakes, or the real
    # filesystem if there is no match
    def select_filesystem(name = nil)
      @@current_fake = @@fakes[name]
    end

    # Return name of file system
    def get_filesystem
      @@current_fake ? @@current_fake[:filesystem] : ''
    end

    # Support 'chdir' for fakes
    alias fakedir_old_chdir chdir
    def chdir(dirname = nil, &blk)
      return fakedir_old_chdir(dirname, &blk) unless @@current_fake
      here = @@current_fake[:cwd]
      node = fakedir_find_node(here, dirname || '/')
      raise Errno::EINVAL, dirname unless node
      @@current_fake[:cwd] = node
      retval = 0
      if blk
        begin
          retval = blk.call(dirname)
        ensure
          @@current_fake[:cwd] = here
        end
      end
      retval
    end

    # Support 'glob' for fakes
    alias fakedir_old_glob glob
    def glob(*args, &blk)
      return fakedir_old_glob(*args, &blk) unless @@current_fake
      patterns = args.to_a
      final = patterns.pop
      flags = 0
      if final && final.kind_of?(Fixnum)
        flags = final
      else
        patterns.push final
      end
      flags
      retval = patterns.collect {|pattern| fakedir_find_all(@@current_fake[:cwd], pattern, flags) }.flatten
      if blk
        retval.each {|name| blk.call(name) }
        return nil
      end
      retval
    end

    # Support 'getwd/pwd' for fakes
    alias fakedir_old_getwd getwd
    def getwd
      return fakedir_old_getwd unless @@current_fake
      @@current_fake[:cwd][:dirname]
    end
    alias fakedir_old_pwd pwd
    def pwd
      return fakedir_old_pwd unless @@current_fake
      @@current_fake[:cwd][:dirname]
    end

    # Support 'entries' for fakes
    alias fakedir_old_entries entries
    def entries(dirname)
      return fakedir_old_entries(dirname) unless @@current_fake
      node = fakedir_find_node(@@current_fake[:cwd], dirname || '.')
      raise Errno::EINVAL, dirname unless node
      ['.', '..'] + node[:files] + node[:dirs].keys
    end

    # Support 'foreach' for fakes
    alias fakedir_old_foreach foreach
    def foreach(dirname, &blk)
      return fakedir_old_foreach(dirname, &blk) unless @@current_fake
      entries(dirname).each {|filename| blk.call(filename)}
      nil
    end

private
    def standardize_path(path)
      path.gsub /\\/, '/'
    end

    def fakedir_find_node(base, cd_directive = '.')
      cd_directive = standardize_path(cd_directive)
      new_base = (cd_directive =~ /^\//) ? cd_directive : "#{base[:dirname]}/#{cd_directive}".gsub(/\/\//,'/')  # Absolute/Relative

      current = @@current_fake  # i.e. '/'
      new_base.split('/').each do |node|
        case node
        when '.', ''
          next  # '.' does nothing
        when '..'
          current = current[:parent]
          return nil unless current
        else
          current = current[:dirs][node.downcase]
          return nil unless current
        end
      end
      return current
    end

    def fakedir_exists?(name)
      #fakedir_find_node(here, name)
      false
    end

    def create_folder_linkage(root_hash, root_name = nil, parent = nil)
      root_hash[:parent] = parent
      root_hash[:dirname] = root_name || '/'
      root_hash[:dirs].each {|name, hash| create_folder_linkage(hash, "#{root_name}/#{name}", root_hash) }
    end

    def fakedir_find_all(root, pattern, flags)
      # File::FNM_PATHNAME)  #=> false : wildcard doesn't match '/' on FNM_PATHNAME
      # File::FNM_NOESCAPE)  #=> true  : FNM_NOESCAPE makes '\' ordinary
      # File::FNM_DOTMATCH)  #=> true    period by default.
      all_files = fakedir_get_all_names(root)
# pp all_files
      if (flags & File::FNM_NOESCAPE) != 0
        pattern = pattern.gsub /\\/, '/'
      end
      actual_pattern = "^#{pattern}$".gsub(/\./, '\\.').gsub(/\?/, '.').gsub(/\*/, '[^/]*')
      matcher = Regexp.new(actual_pattern, Regexp::IGNORECASE)
      puts "pattern:#{pattern}|#{actual_pattern}|#{matcher}, flags:#{flags}"
      all_files = all_files.select{|f| matcher.match(f)}

      if (flags & File::FNM_DOTMATCH) == 0
        all_files = all_files.select{|f| f !~ /\/\./}.select{|f| f !~ /^\./}
      end
      
      all_files
    end

    # Gets an array of names of all files from the rot node down
    # Names have directory prefixes if needed
    def fakedir_get_all_names(root, basename = '')
      result = (['.', '..'] + root[:files] + root[:dirs].keys).map{|e| basename + e}
      root[:dirs].each do |name, content|
        result += fakedir_get_all_names(content, "#{basename}#{name}/")
      end
      result
    end
  end
end