require 'spec_helper'

require 'message_driver/adapters/in_memory_adapter'

module MessageDriver
  describe Client do
    class TestPublisher
      include Client
    end

    let(:adapter) { Adapters::InMemoryAdapter.new }
    before do
      MessageDriver.configure(adapter: adapter)
    end

    let(:adapter_context) { subject.current_adapter_context }

    shared_examples "a Client" do
      describe "#publish" do
        let(:destination) { Broker.destination(:my_queue, "my_queue", exclusive: true) }
        let(:body) { "my message" }
        let(:headers) { {foo: :bar} }
        let(:properties) { {bar: :baz} }

        it "delegates to the destination" do
          destination.should_receive(:publish).with(body, headers, properties)
          subject.publish(destination, body, headers, properties)
        end

        it "looks up the destination if necessary" do
          destination.should_receive(:publish).with(body, headers, properties)
          subject.publish(:my_queue, body, headers, properties)
        end

        context "when the destination can't be found" do
          let(:bad_dest_name) { :not_a_queue }
          it "raises a MessageDriver:NoSuchDestinationError" do
            expect {
              subject.publish(bad_dest_name, body, headers, properties)
            }.to raise_error(MessageDriver::NoSuchDestinationError, /#{bad_dest_name}/)
          end
        end

        it "only requires destination and body" do
          destination.should_receive(:publish).with(body, {}, {})
          subject.publish(destination, body)
        end
      end

      describe "#pop_message" do
        let(:expected) { double(MessageDriver::Message) }
        let(:destination) { Broker.destination(:my_queue, "my_queue", exclusive: true) }
        let(:options) { {foo: :bar} }

        it "delegates to the destination" do
          destination.should_receive(:pop_message).with(options)
          subject.pop_message(destination, options)
        end

        it "looks up the destination if necessary" do
          destination.should_receive(:pop_message).with(options)
          subject.pop_message(:my_queue, options)
        end

        context "when the destination can't be found" do
          let(:bad_dest_name) { :not_a_queue }
          it "raises a MessageDriver:NoSuchDestinationError" do
            expect {
              subject.pop_message(bad_dest_name, options)
            }.to raise_error(MessageDriver::NoSuchDestinationError, /#{bad_dest_name}/)
          end
        end

        it "requires the destination and returns the message" do
          destination.should_receive(:pop_message).with({}).and_return(expected)

          actual = subject.pop_message(destination)

          expect(actual).to be expected
        end

       it "passes the options through and returns the message" do
          destination.should_receive(:pop_message).with(options).and_return(expected)

          actual = subject.pop_message(destination, options)

          expect(actual).to be expected
        end
      end

      describe "#with_message_transaction" do
        it "delegates to the adapter context" do
          expected = lambda do; end
          adapter_context.should_receive(:with_transaction) do |&actual|
            expect(actual).to be(expected)
          end
          subject.with_message_transaction(&expected)
        end
      end

      describe "#subscribe" do
        let(:destination) { Broker.destination(:my_queue, "my_queue", exclusive: true) }
        let(:consumer_double) { lambda do |m| end }

        before do
          Broker.consumer(:my_consumer, &consumer_double)
        end

        it "delegates to the destination" do
          destination.should_receive(:subscribe) do |&block|
            expect(block).to be(consumer_double)
          end
          subject.subscribe(destination, :my_consumer)
        end

        it "looks up the destination" do
          destination.should_receive(:subscribe) do |&block|
            expect(block).to be(consumer_double)
          end
          subject.subscribe(:my_queue, :my_consumer)
        end

        context "when the destination can't be found" do
          let(:bad_dest_name) { :not_a_queue }
          it "raises a MessageDriver:NoSuchDestinationError" do
            expect {
              subject.subscribe(bad_dest_name, :my_consumer)
            }.to raise_error(MessageDriver::NoSuchDestinationError, /#{bad_dest_name}/)
          end
        end

        context "when the consumer can't be found" do
          let(:bad_consumer_name) { :not_a_consumer }
          it "raises a MessageDriver:NoSuchConsumerError" do
            expect {
              subject.subscribe(destination, bad_consumer_name)
            }.to raise_error(MessageDriver::NoSuchConsumerError, /#{bad_consumer_name}/)
          end
        end
      end
    end

    context "when used as an included module" do
      subject { TestPublisher.new }
      it_behaves_like "a Client"
    end

    context "when the module is used directly" do
      subject { described_class }
      it_behaves_like "a Client"
    end
  end
end
