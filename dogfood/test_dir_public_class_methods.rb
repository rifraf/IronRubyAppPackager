require 'test/unit'

class TestTwinFileSystems < Test::Unit::TestCase

  def setup
    Dir.select_filesystem('Serfs')
    Dir.chdir '/'
  end
  
  def test_can_switch_filesystems  
    assert_equal('Serfs', Dir.get_filesystem, "Should start in fake file system")
    assert_equal('/', Dir.getwd, 'Should start at root of fake file system')

    Dir.select_filesystem()
    assert_equal('', Dir.get_filesystem, "Should switch to real file system")
    assert_equal(File.dirname(__FILE__), Dir.getwd, 'Should be in real file system')
    assert_not_equal('/', Dir.getwd, 'Should not be at root')

    Dir.select_filesystem('Serfs')
    assert_equal('Serfs', Dir.get_filesystem, "Should be back in fake file system")
    assert_equal('/', Dir.getwd, 'Should still be at root of fake file system')
  end
  
end

# ---------------------------------------------------------------
# We test the behaviour of the native filesystem so that we
# can be sure it does not get broken by the monkey-patching
# ---------------------------------------------------------------
class TestNativeDirectoryMethods < Test::Unit::TestCase
  def setup
    Dir.select_filesystem()
    @here = Dir.getwd
  end

  def teardown
    Dir.chdir(@here)
  end

  def test_native_baddir
    assert_raise Errno::EINVAL do
      Dir.chdir('doodaa')
    end
  end

  def test_native_chdir_noblock
    first = Dir.getwd
    assert_equal 0, Dir.chdir('..')
    second = Dir.getwd
    assert_equal 0, first.index(second), "cd(..) should give us a path that starts the same"
    assert( (first.length > second.length), "second should just be shorter")
  end

  def test_native_chdir_withblock
    first = Dir.getwd
    assert_equal 'boo', Dir.chdir('..') {|d|
      assert_equal '..', d, "Block value should be whatever was passed in"
      second = Dir.getwd
      assert_equal 0, first.index(second), "cd(..) should give us a path that starts the same"
      assert( (first.length > second.length), "second should just be shorter")
      'boo'
    }
    third = Dir.getwd
    assert_equal first, third, "cd {} should keep current dir around block"
  end

  def test_native_foreach
    count = 0
    assert_nil Dir.foreach('.') {|name|
      count += 1
    }
    assert count > 2
  end

  def test_native_glob_noblock
    assert(Dir.glob('**/*.rb', 0).length > 0)
  end

  def test_native_glob_withblock
    count = 0
    Dir.glob('**/*.rb') {|n| count += 1 }
    assert(count > 2)
  end

end

# ---------------------------------------------------------------
# Here we test Serfs version
# ---------------------------------------------------------------
class TestFakeDirectoryMethods < Test::Unit::TestCase
  def setup
    Dir.select_filesystem('Serfs')
    @here = Dir.getwd
  end

  def test_fake_baddir
    assert_raise Errno::EINVAL do
      Dir.chdir('doodaa')
    end
  end

  def test_fake_chdir_noblock
    assert_equal '/', Dir.getwd, "Fake starts at root directory"
    
    assert_equal 0, Dir.chdir('/test'), "chdir should return zero"
    
    assert_equal '/test', Dir.getwd, "Should be able to set absolute path"

    Dir.chdir('unit/collector')
    assert_equal '/test/unit/collector', Dir.getwd, "Should be able to set relative path"

    Dir.chdir('../..')
    assert_equal '/test', Dir.getwd, "Should be able to go backwards"

    Dir.chdir('./unit/ui/./console')
    assert_equal '/test/unit/ui/console', Dir.getwd, "Should support '.'"

    Dir.chdir('./')
    assert_equal '/test/unit/ui/console', Dir.getwd, "Should not change"

    Dir.chdir()
    assert_equal '/', Dir.getwd, "Should be back at root (home)"

  end

  def test_fake_chdir_withblock
    first = Dir.getwd
    assert_equal 'baa', Dir.chdir('test') {|d|
      assert_equal 'test', d, "Block value should be whatever was passed in"
      assert_equal '/test', Dir.getwd, "cd(test)"
      'baa'
    }
    third = Dir.getwd
    assert_equal first, third, "cd {} should keep current dir around block"
  end

  def test_fake_entries
    root_entries1 = Dir.entries('/')
    root_entries2 = Dir.entries('/test/..')
    Dir.chdir('test')
    root_entries3 = Dir.entries('..')
    assert_equal root_entries1, root_entries2, "'/' and '/test/..' should return same info"
    assert_equal root_entries1, root_entries3, "'/' and '..' in test should return same info"
    assert root_entries1.include?('.')
    assert root_entries1.include?( '..')
    assert root_entries1.include?("test_dir_public_class_methods.rb")
    assert root_entries1.include?("_SerfsDirInfo_")
    assert root_entries1.include?("EmbeddedRuby")
    assert root_entries1.include?("test")
  end

  def test_fake_badentries
    assert_raise Errno::EINVAL do
      Dir.entries('/doodaa')
    end
  end

  def test_fake_foreach
    entries = []
    assert_nil Dir.foreach('/.') {|name|
      entries << name
    }
    assert entries.include?('.')
    assert entries.include?( '..')
    assert entries.include?("test_dir_public_class_methods.rb")
    assert entries.include?("_SerfsDirInfo_")
    assert entries.include?("EmbeddedRuby")
    assert entries.include?("test")
  end

  def test_fake_badforeach
    assert_raise Errno::EINVAL do
      Dir.foreach('/doodaa') {}
    end
  end

  def test_fake_glob_noblock
    Dir.chdir '/test'
    assert_equal 1, Dir.glob("unit.rb").length, "1 unit.rb"
    assert_equal 1, Dir.glob("unit.??").length, "1 unit.??"
    assert_equal 0, Dir.glob("unit.?").length,  "1 unit.?"

    assert_equal 1, Dir.glob("u[a-z]it.r[a-z]").length, "1 u[a-z].r[a-z]"

    assert_equal 1, Dir.glob("unit.*").length, "1 unit.*"
    assert_equal 2, Dir.glob("u*").length, "2 u*" # file and folder
    assert_equal 1, Dir.glob("*rb").length, "1 *rb"

    assert_equal 1, Dir.glob("unit/collector/ob*").length, "1 unit/collector/ob*"
    assert_equal 0, Dir.glob("unit/collector\\ob*").length, "0 unit/collector\\ob*"
    assert_equal 1, Dir.glob("unit/collector\\ob*", File::FNM_NOESCAPE).length, "1 with File::FNM_NOESCAPE unit/collector\\ob*"

    set = Dir.glob('unit/[^T]*')
    assert set.length > 6
    assert_nil set.find {|f| f =~ /test/}

    set_size = Dir.glob("*").length
    assert_equal set_size + 2, Dir.glob("*", File::FNM_DOTMATCH).length, "2 more with File::FNM_DOTMATCH"

    set_size = Dir.glob("unit/*").length
    assert_equal set_size + 2, Dir.glob("unit/*", File::FNM_DOTMATCH).length, "2 more with File::FNM_DOTMATCH"

#   Dir.glob("**/*.rb")
#   Dir.glob("**/unit")
#   Dir.glob("**/unit/**/*.rb")
#   Dir.glob("/**/ui/*.rb")

  end

  def test_fake_glob_withblock
    #count = 0
    #Dir.glob('**/*.rb') {|n| count += 1 }
    #assert(count > 2)
  end


end
