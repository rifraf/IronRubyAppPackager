# MicroTest
puts "Loading MicroTest" if ENV['debug']

#require 'rubygems' if this_ruby.features[:bad_rubyopt] && !this_ruby.features[:no_gems]

class MicroTest
	attr_reader :passes, :fails
	
	def initialize(name)
		puts "Starting: #{name}"
		@passes = 0
		@fails = 0
	end

	def assert(truth, text = '')
	  unless truth
	    puts "Expected: true, Actual: #{truth}. #{text}"
	    @fails += 1
	  else
	    @passes += 1
	  end
	end


	def assert_equal(expected, actual, text = '')
	  if expected != actual
	    puts "Expected: #{expected}, Actual: #{actual}. #{text}"
	    @fails += 1
	  else
	    @passes += 1
	  end
	end

	def assert_not_equal(expected, actual, text = '')
	  if expected == actual
	    puts "Expected: #{expected} should not equal Actual: #{actual}. #{text}"
	    @fails += 1
	  else
	    @passes += 1
	  end
	end
	
	def complete
	  puts "Pass:#{@passes}, fail:#{@fails}"
	  exit(@fails) if @fails > 0
	end
		
	
end