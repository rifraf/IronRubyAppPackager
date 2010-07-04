require 'test/unit'

=begin
  Dir[ array ] => array
Dir[ string [, string ...] ] => array

Equivalent to calling Dir.glob(array,0) and Dir.glob(,0).
Dir.chdir( [ string] ) => 0
Dir.chdir( [ string] ) {| path | block } => anObject

Changes the current working directory of the process to the given string. When called without an argument, changes the directory to the value of the environment variable HOME, or LOGDIR. SystemCallError (probably Errno::ENOENT) if the target directory does not exist.

If a block is given, it is passed the name of the new current directory, and the block is executed with that as the current directory. The original working directory is restored when the block exits. The return value of chdir is the value of the block. chdir blocks can be nested, but in a multi-threaded program an error will be raised if a thread attempts to open a chdir block while another thread has one open.

   Dir.chdir("/var/spool/mail")
   puts Dir.pwd
   Dir.chdir("/tmp") do
     puts Dir.pwd
     Dir.chdir("/usr") do
       puts Dir.pwd
     end
     puts Dir.pwd
   end
   puts Dir.pwd

produces:

   /var/spool/mail
   /tmp
   /usr
   /tmp
   /var/spool/mail

Dir.chroot( string ) => 0

Changes this process‘s idea of the file system root. Only a privileged process may make this call. Not available on all platforms. On Unix systems, see chroot(2) for more information.
Dir.delete( string ) => 0
Dir.rmdir( string ) => 0
Dir.unlink( string ) => 0

Deletes the named directory. Raises a subclass of SystemCallError if the directory isn‘t empty.
Dir.entries( dirname ) => array

Returns an array containing all of the filenames in the given directory. Will raise a SystemCallError if the named directory doesn‘t exist.

   Dir.entries("testdir")   #=> [".", "..", "config.h", "main.rb"]

Dir.foreach( dirname ) {| filename | block } => nil

Calls the block once for each entry in the named directory, passing the filename of each entry as a parameter to the block.

   Dir.foreach("testdir") {|x| puts "Got #{x}" }

produces:

   Got .
   Got ..
   Got config.h
   Got main.rb

Dir.getwd => string
Dir.pwd => string

Returns the path to the current working directory of this process as a string.

   Dir.chdir("/tmp")   #=> 0
   Dir.getwd           #=> "/tmp"

Dir.glob( pattern, [flags] ) => array
Dir.glob( pattern, [flags] ) {| filename | block } => nil

Returns the filenames found by expanding pattern which is an Array of the patterns or the pattern String, either as an array or as parameters to the block. Note that this pattern is not a regexp (it‘s closer to a shell glob). See File::fnmatch for the meaning of the flags parameter. Note that case sensitivity depends on your system (so File::FNM_CASEFOLD is ignored)
*:	Matches any file. Can be restricted by other values in the glob. * will match all files; c* will match all files beginning with c; *c will match all files ending with c; and c will match all files that have c in them (including at the beginning or end). Equivalent to / .* /x in regexp.
**:	Matches directories recursively.
?:	Matches any one character. Equivalent to /.{1}/ in regexp.
[set]:	Matches any one character in set. Behaves exactly like character sets in Regexp, including set negation ([^a-z]).
{p,q}:	Matches either literal p or literal q. Matching literals may be more than one character in length. More than two literals may be specified. Equivalent to pattern alternation in regexp.
<code></code>:	Escapes the next metacharacter.

   Dir["config.?"]                     #=> ["config.h"]
   Dir.glob("config.?")                #=> ["config.h"]
   Dir.glob("*.[a-z][a-z]")            #=> ["main.rb"]
   Dir.glob("*.[^r]*")                 #=> ["config.h"]
   Dir.glob("*.{rb,h}")                #=> ["main.rb", "config.h"]
   Dir.glob("*")                       #=> ["config.h", "main.rb"]
   Dir.glob("*", File::FNM_DOTMATCH)   #=> [".", "..", "config.h", "main.rb"]

   rbfiles = File.join("**", "*.rb")
   Dir.glob(rbfiles)                   #=> ["main.rb",
                                            "lib/song.rb",
                                            "lib/song/karaoke.rb"]
   libdirs = File.join("**", "lib")
   Dir.glob(libdirs)                   #=> ["lib"]

   librbfiles = File.join("**", "lib", "**", "*.rb")
   Dir.glob(librbfiles)                #=> ["lib/song.rb",
                                            "lib/song/karaoke.rb"]

   librbfiles = File.join("**", "lib", "*.rb")
   Dir.glob(librbfiles)                #=> ["lib/song.rb"]

Dir.mkdir( string [, integer] ) => 0

Makes a new directory named by string, with permissions specified by the optional parameter anInteger. The permissions may be modified by the value of File::umask, and are ignored on NT. Raises a SystemCallError if the directory cannot be created. See also the discussion of permissions in the class documentation for File.
Dir.new( string ) → aDir

Returns a new directory object for the named directory.
Dir.open( string ) => aDir
Dir.open( string ) {| aDir | block } => anObject

With no block, open is a synonym for Dir::new. If a block is present, it is passed aDir as a parameter. The directory is closed at the end of the block, and Dir::open returns the value of the block.
Dir.getwd => string
Dir.pwd => string

Returns the path to the current working directory of this process as a string.

   Dir.chdir("/tmp")   #=> 0
   Dir.getwd           #=> "/tmp"

Dir.delete( string ) => 0
Dir.rmdir( string ) => 0
Dir.unlink( string ) => 0

Deletes the named directory. Raises a subclass of SystemCallError if the directory isn‘t empty.
tmpdir()

Returns the operating system‘s temporary file path.
Dir.delete( string ) => 0
Dir.rmdir( string ) => 0
Dir.unlink( string ) => 0

Deletes the named directory. Raises a subclass of SystemCallError if the directory isn‘t empty.

=end

class TestTwinFileSystems < Test::Unit::TestCase

  def setup
    Dir.select_filesystem('Serfs')
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
    Dir.chdir('..')
    second = Dir.getwd
    assert_equal 0, first.index(second), "cd(..) should give us a path that starts the same"
    assert( (first.length > second.length), "second should just be shorter")
  end

  def test_native_chdir_withblock
    first = Dir.getwd
    Dir.chdir('..') {|d|
      assert_equal '..', d, "Block value should be whatever was passed in"
      second = Dir.getwd
      assert_equal 0, first.index(second), "cd(..) should give us a path that starts the same"
      assert( (first.length > second.length), "second should just be shorter")
    }
    third = Dir.getwd
    assert_equal first, third, "cd {} should keep current dir around block"
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
    
    Dir.chdir('/test')
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

  def test_withblock

  end

end
