ENV['RACK_ENV'] ||= 'development'
require 'bundler/setup'

require 'base64'
require 'slim'
require 'rhino'
require 'coffee-script'

require_relative 'lib/torquebox_message_broker'
require_relative 'lib/sse_publisher'
require_relative 'lib/file_chunker'

require 'sinatra'

broker = TorqueboxMessageBroker.new

get '/' do
  slim :index
end

post '/message' do
  broker.send_to_all(params)

  status 201
end

post '/file' do
  chunks = FileChunker.new(params[:file][:tempfile])

  begin
    chunks.each do |chunk|
      broker.send_to_all(
        event:     "FILEDATA",
        filename:  params[:file][:filename],
        data:      Base64.encode64(chunk).gsub("\n", "")
      )
    end
  ensure
    broker.send_to_all(event: "FILEEND", filename: params[:file][:filename])
  end
end

get '/stream', provides: 'text/event-stream' do
  headers['Transfer-Encoding'] = 'chunked'

  stream do |out|
    sse = SsePublisher.new(out)

    sse.publish("HELLO", hello: "world")
    broker.receive do |message|
      sse.publish(message[:event], message)
    end
  end
end

get '/message.js' do
  coffee :message
end
