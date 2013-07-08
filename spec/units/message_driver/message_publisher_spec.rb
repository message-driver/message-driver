require 'spec_helper'

require 'message_driver/adapters/in_memory_adapter'

module MessageDriver
  describe MessageDriver::MessagePublisher do
    class TestPublisher
      include MessageDriver::MessagePublisher
    end

    let(:adapter) { Adapters::InMemoryAdapter.new }
    before do
      MessageDriver.configure(adapter: adapter)
    end

    subject { TestPublisher.new }

    describe "#publish" do
      let(:destination) { "my_queue" }
      let(:body) { "my message body" }

      it "only requires destination and body" do
        Broker.instance.should_receive(:publish).with(destination, body, {}, {})

        subject.publish(destination, body)
      end

      let(:headers) { {foo: :bar} }
      let(:properties) { {bar: :baz} }

      it "also passes through the headers and properties" do
        Broker.instance.should_receive(:publish).with(destination, body, headers, properties)

        subject.publish(destination, body, headers, properties)
      end
    end

    describe "#pop_message" do
      let(:destination) { "my_queue" }
      let(:expected) { double(MessageDriver::Message) }

      it "requires the destination and returns the message" do
        Broker.instance.should_receive(:pop_message).with(destination, {}).and_return(expected)

        actual = subject.pop_message(destination)

        expect(actual).to be expected
      end

      let(:options) { {foo: :bar} }

      it "passes the options through and returns the message" do
        Broker.instance.should_receive(:pop_message).with(destination, options).and_return(expected)

        actual = subject.pop_message(destination, options)

        expect(actual).to be expected
      end
    end

    describe "#with_message_transaction" do
      it "needs some real tests"
    end
  end
end
