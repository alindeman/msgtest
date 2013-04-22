require "securerandom"
require "torquebox-messaging"

class MessageBroker
  def initialize(client_id = SecureRandom.hex)
    @topic = TorqueBox::Messaging::Topic.start("/topics/global_messages")
    @topic.connect_options[:client_id] = client_id
  end

  def send_to_all(message)
    @topic.publish(message, encoding: :json)
  end

  def receive(&blk)
    loop do
      @topic.receive(durable: true, &blk)
    end
  ensure
    @topic.unsubscribe
  end
end
