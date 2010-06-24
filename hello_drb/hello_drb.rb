require 'drb'

uri="druby://localhost:8787"

class HelloTimeServer
  def say_hi
    return "Hello, the time is #{Time.now}"
  end
end

DRb.start_service(uri, HelloTimeServer.new)

hello_server = DRbObject.new_with_uri(uri)
puts hello_server.say_hi

