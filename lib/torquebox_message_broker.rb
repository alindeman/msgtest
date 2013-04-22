require "securerandom"
require "torquebox-messaging"

class TorqueboxMessageBroker
  GLOBAL_TOPIC = "/topics/global_messages"

  def send_to_all(message)
    topic = TorqueBox::Messaging::Topic.start(GLOBAL_TOPIC)
    topic.publish(message, encoding: :json)
  end

  def receive(client_id = SecureRandom.hex, &blk)
    topic = TorqueBox::Messaging::Topic.start(GLOBAL_TOPIC)
    topic.connect_options[:client_id] = client_id
    begin
      loop { topic.receive(durable: true, &blk) }
    ensure
      topic.unsubscribe
    end
  end
end
