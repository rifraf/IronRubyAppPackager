#
# With require 'vendorize' present, any files that are not already in
# the _vendor_ cache will get added to it. If all files are in 
# the cache, they are the ones that get used. If necessary,
# several runs of a program can be made to populate the
# cache.
# Note: If you have requires in the rupyopt environment variable,
# (e.g. rubyopt=rubygems), then you can't put the require here because
# it will be too late. Instead, launch with ruby -rvendorize ... or add
# it into the rubyopt
#
#require 'vendorize' unless vendor_only?
puts "Testing drb"

require 'microtest'

	
	test = MicroTest.new('DRB')
	
	require 'drb'
  # The URI for the server to connect to
  uri="druby://localhost:8787"

  class TimeServer
    def get_current_time
      return Time.now
    end
  end

  DRb.start_service(uri, TimeServer.new)

  timeserver = DRbObject.new_with_uri(uri)
  puts timeserver.get_current_time
	test.assert_equal timeserver.get_current_time.to_s[0...10], Time.now.to_s[0...10]
	test.complete()
	
