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
      if blk
        begin
          blk.call dirname
        ensure
          @@current_fake[:cwd] = here
        end
      end
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
  end
end