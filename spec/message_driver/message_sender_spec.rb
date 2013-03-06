require 'spec_helper'

require 'message_driver/adapters/in_memory_adapter'

module MessageDriver
  describe MessageDriver::MessageSender do
    class TestSender
      include MessageDriver::MessageSender
    end

    let(:adapter) { Adapters::InMemoryAdapter.new }
    before do
      MessageDriver.configure(adapter: adapter)
    end

    subject { TestSender.new }

    describe "#send_message" do
      let(:destination) { "my_queue" }
      let(:body) { "my message body" }

      it "only requires destination and body" do
        Broker.instance.should_receive(:send_message).with(destination, body, {}, {})

        subject.send_message(destination, body)
      end

      let(:headers) { {foo: :bar} }
      let(:properties) { {bar: :baz} }

      it "also passes through the headers and properties" do
        Broker.instance.should_receive(:send_message).with(destination, body, headers, properties)

        subject.send_message(destination, body, headers, properties)
      end
    end
  end
end
