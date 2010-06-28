begin
  unless ENV['NO_COLOUR']
    # IronRuby?
    if defined?(RUBY_ENGINE && RUBY_ENGINE =~ "ironruby")
      require 'rubygems'
      libname = 'iron-term-ansicolor'
      require libname
    else
      # else MRI?
      require 'rubygems'
      libname = 'win32console'
      require libname
      libname = 'term/ansicolor'
      require libname
      include Win32::Console::ANSI
      include Term::ANSIColor
      class String
        include Term::ANSIColor
      end
    end
    puts "Loaded #{libname}".green
  end
rescue LoadError
  puts "No '#{libname}' ((i)gem install #{libname})"
end

unless "".respond_to?(:red, true)
  # No colour support. Fake it.
  class String
    def red; self; end
    def magenta; self; end
    def yellow; self; end
    def cyan; self; end
    def green; self; end
  end
end