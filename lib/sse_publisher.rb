require 'json'

class SsePublisher
  def initialize(io)
    @io = io
  end

  def publish(event, message)
    puts "Publishing #{event}"
    @io << "event: #{event}\ndata: #{JSON.dump(message)}\n\n"
  end
end
