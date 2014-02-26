require 'spec_helper'

require 'message_driver/adapters/in_memory_adapter'

module MessageDriver
  describe Client do
    class TestPublisher
      include Client
    end

    let(:logger) { MessageDriver.logger }
    let(:broker_name) { Broker::DEFAULT_BROKER_NAME }
    let!(:broker) { Broker.configure(broker_name, adapter: Adapters::InMemoryAdapter, logger: logger) }
    let(:adapter) { broker.adapter }
    let(:adapter_context) { adapter.new_context }

    shared_examples "a Client" do
      describe "#broker" do
        it "returns the broker_name" do
          expect(subject.broker_name).to eq(broker_name)
        end
      end

      describe "#current_adapter_context" do
        before { subject.clear_context }

        it "returns an adapter_context" do
          expect(subject.current_adapter_context).to be_a Adapters::ContextBase
        end

        it "returns the same adapter context on the second call" do
          ctx = subject.current_adapter_context
          expect(subject.current_adapter_context).to be ctx
        end

        context "when called with false" do
          it "doesn't initialize the adapter context if there isn't one" do
            expect(subject.current_adapter_context(false)).to be_nil
          end
        end
      end

      context "with a given adapter_context" do
        around(:each) do |example|
          subject.with_adapter_context(adapter_context, &example)
        end

        describe "#dynamic_destination" do
          let(:dest_name) { "my_new_queue" }
          let(:dest_options) { {type: 2} }
          let(:message_props) { {expires: "soon"} }
          let(:created_dest) { double("created destination") }
          before do
            adapter_context.stub(:create_destination) { created_dest }
          end

          it "delegates to the adapter_context" do
            result = subject.dynamic_destination(dest_name, dest_options, message_props)
            expect(result).to be(created_dest)

            adapter_context.should have_received(:create_destination).with(dest_name, dest_options, message_props)
          end

          it "only requires destination name" do
            result = subject.dynamic_destination(dest_name)
            expect(result).to be(created_dest)

            adapter_context.should have_received(:create_destination).with(dest_name, {}, {})
          end
        end

        describe "#publish" do
          let(:destination) { broker.destination(:my_queue, "my_queue", exclusive: true) }
          let(:body) { "my message" }
          let(:headers) { {foo: :bar} }
          let(:properties) { {bar: :baz} }
          before do
            adapter_context.stub(:publish)
          end

          it "delegates to the adapter_context" do
            subject.publish(destination, body, headers, properties)
            adapter_context.should have_received(:publish).with(destination, body, headers, properties)
          end

          it "only requires destination and body" do
            subject.publish(destination, body)
            adapter_context.should have_received(:publish).with(destination, body, {}, {})
          end

          it "looks up the destination if necessary" do
            destination
            subject.publish(:my_queue, body, headers, properties)
            adapter_context.should have_received(:publish).with(destination, body, headers, properties)
          end

          context "when the destination can't be found" do
            let(:bad_dest_name) { :not_a_queue }
            it "raises a MessageDriver:NoSuchDestinationError" do
              expect {
                subject.publish(bad_dest_name, body, headers, properties)
              }.to raise_error(MessageDriver::NoSuchDestinationError, /#{bad_dest_name}/)
              adapter_context.should_not have_received(:publish)
            end
          end
        end

        describe "#pop_message" do
          let(:expected) { double(MessageDriver::Message) }
          let(:destination) { broker.destination(:my_queue, "my_queue", exclusive: true) }
          let(:options) { {foo: :bar} }
          before do
            adapter_context.stub(:pop_message)
          end

          it "delegates to the adapter_context" do
            subject.pop_message(destination, options)
            adapter_context.should have_received(:pop_message).with(destination, options)
          end

          it "looks up the destination if necessary" do
            destination
            subject.pop_message(:my_queue, options)
            adapter_context.should have_received(:pop_message).with(destination, options)
          end

          context "when the destination can't be found" do
            let(:bad_dest_name) { :not_a_queue }
            it "raises a MessageDriver:NoSuchDestinationError" do
              expect {
                subject.pop_message(bad_dest_name, options)
              }.to raise_error(MessageDriver::NoSuchDestinationError, /#{bad_dest_name}/)
              adapter_context.should_not have_received(:pop_message)
            end
          end

          it "requires the destination and returns the message" do
            adapter_context.should_receive(:pop_message).with(destination, {}).and_return(expected)

            actual = subject.pop_message(destination)

            expect(actual).to be expected
          end

          it "passes the options through and returns the message" do
            adapter_context.should_receive(:pop_message).with(destination, options).and_return(expected)

            actual = subject.pop_message(destination, options)

            expect(actual).to be expected
          end
        end

        describe "#with_message_transaction" do
          before do
            adapter_context.stub(:begin_transaction)
            adapter_context.stub(:commit_transaction)
            adapter_context.stub(:rollback_transaction)
          end

          context "when the adapter supports transactions" do
            before do
              adapter_context.stub(:supports_transactions?) { true }
            end
            it "delegates to the adapter context" do
              expect { |blk|
                subject.with_message_transaction(&blk)
              }.to yield_control
              adapter_context.should have_received(:begin_transaction)
              adapter_context.should have_received(:commit_transaction)
            end

            context "when the block raises an error" do
              it "calls rollback instead of commit and raises the error" do
                expect {
                  subject.with_message_transaction do
                    raise "having a tough time"
                  end
                }.to raise_error "having a tough time"
                adapter_context.should have_received(:begin_transaction)
                adapter_context.should_not have_received(:commit_transaction)
                adapter_context.should have_received(:rollback_transaction)
              end

              context "and the the rollback raises an error" do
                it "logs the error from the rollback and raises the original error" do
                  allow(logger).to receive(:error)
                  adapter_context.stub(:rollback_transaction).and_raise("rollback failed!")
                  expect {
                    subject.with_message_transaction do
                      raise "having a tough time"
                    end
                  }.to raise_error "having a tough time"
                  expect(logger).to have_received(:error).with(match("rollback failed!"))
                end
              end
            end

            context "when the transactions are nested" do
              it "only starts and commits once" do
                expect { |blk|
                  subject.with_message_transaction do
                    subject.with_message_transaction(&blk)
                  end
                }.to yield_control
                adapter_context.should have_received(:begin_transaction).once
                adapter_context.should have_received(:commit_transaction).once
              end

              context "when the block raises an error" do
                it "calls rollback instead of commit and raises the error" do
                  expect {
                    subject.with_message_transaction do
                      subject.with_message_transaction do
                        raise "having a tough time"
                      end
                    end
                  }.to raise_error "having a tough time"
                  adapter_context.should have_received(:begin_transaction).once
                  adapter_context.should_not have_received(:commit_transaction)
                  adapter_context.should have_received(:rollback_transaction).once
                end
              end
            end
          end

          context "when the adapter doesn't support transactions" do
            before do
              adapter_context.stub(:supports_transactions?) { false }
            end
            it "run the block on it's own" do
              expect { |blk|
                subject.with_message_transaction(&blk)
              }.to yield_control
              adapter_context.should_not have_received(:begin_transaction)
              adapter_context.should_not have_received(:commit_transaction)
              adapter_context.should_not have_received(:rollback_transaction)
            end
            it "logs a warning" do
              allow(logger).to receive(:debug)
              expect { |blk|
                subject.with_message_transaction(&blk)
              }.to yield_control
              expect(logger).to have_received(:debug).with("this adapter does not support transactions")
            end
          end
        end

        describe "#ack_message" do
          let(:message) { double("message") }
          let(:options) { {foo: :bar} }
          before do
            allow(message).to receive(:ack)
          end
          it "calls #ack on the message" do
            subject.ack_message(message)
            expect(message).to have_received(:ack).with({})
          end
          it "calls #ack on the message and passes the supplied options" do
            subject.ack_message(message, options)
            expect(message).to have_received(:ack).with(options)
          end
        end

        describe "#nack_message" do
          let(:message) { double("message") }
          let(:options) { {foo: :bar} }
          before do
            allow(message).to receive(:nack)
          end
          it "calls #nack on the message" do
            subject.nack_message(message)
            expect(message).to have_received(:nack).with({})
          end
          it "calls #nack on the message and passes the supplied options" do
            subject.nack_message(message, options)
            expect(message).to have_received(:nack).with(options)
          end
        end

        describe "#subscribe" do
          let(:destination) { broker.destination(:my_queue, "my_queue", exclusive: true) }
          let(:consumer_double) { lambda do |m| end }

          before do
            adapter_context.stub(:subscribe)
            broker.consumer(:my_consumer, &consumer_double)
          end

          it "delegates to the adapter_context" do
            adapter_context.should_receive(:subscribe).with(destination, {}) do |&blk|
              expect(blk).to be(consumer_double)
            end
            subject.subscribe(destination, :my_consumer)
          end

          it "passes the options through" do
            options = {foo: :bar}
            adapter_context.should_receive(:subscribe).with(destination, options) do |&blk|
              expect(blk).to be(consumer_double)
            end
            subject.subscribe(destination, :my_consumer, options)
          end

          it "looks up the destination" do
            adapter_context.should_receive(:subscribe).with(destination, {}) do |&blk|
              expect(blk).to be(consumer_double)
            end
            subject.subscribe(:my_queue, :my_consumer)
          end

          context "when the destination can't be found" do
            let(:bad_dest_name) { :not_a_queue }
            it "raises a MessageDriver:NoSuchDestinationError" do
              expect {
                subject.subscribe(bad_dest_name, :my_consumer)
              }.to raise_error(MessageDriver::NoSuchDestinationError, /#{bad_dest_name}/)
              adapter_context.should_not have_received(:subscribe)
            end
          end

          context "when the consumer can't be found" do
            let(:bad_consumer_name) { :not_a_consumer }
            it "raises a MessageDriver:NoSuchConsumerError" do
              expect {
                subject.subscribe(destination, bad_consumer_name)
              }.to raise_error(MessageDriver::NoSuchConsumerError, /#{bad_consumer_name}/)
              adapter_context.should_not have_received(:subscribe)
            end
          end
        end

        describe "#subscribe_with" do
          let(:destination) { broker.destination(:my_queue, "my_queue", exclusive: true) }
          let(:consumer_double) { lambda do |m| end }

          before do
            adapter_context.stub(:subscribe)
          end

          it "delegates to the adapter_context" do
            adapter_context.should_receive(:subscribe).with(destination, {}) do |&blk|
              expect(blk).to be(consumer_double)
            end
            subject.subscribe_with(destination, &consumer_double)
          end

          it "passes the options through" do
            options = {foo: :bar}
            adapter_context.should_receive(:subscribe).with(destination, options) do |&blk|
              expect(blk).to be(consumer_double)
            end
            subject.subscribe_with(destination, options, &consumer_double)
          end

          it "looks up the destination" do
            adapter_context.should_receive(:subscribe).with(destination, {}) do |&blk|
              expect(blk).to be(consumer_double)
            end
            subject.subscribe_with(:my_queue, &consumer_double)
          end

          context "when the destination can't be found" do
            let(:bad_dest_name) { :not_a_queue }
            it "raises a MessageDriver:NoSuchDestinationError" do
              expect {
                subject.subscribe_with(bad_dest_name, &consumer_double)
              }.to raise_error(MessageDriver::NoSuchDestinationError, /#{bad_dest_name}/)
              adapter_context.should_not have_received(:subscribe)
            end
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

    describe ".for_broker" do
      let(:broker_name) { :my_cool_broker }
      let(:client) { described_class.for_broker(broker_name) }
      it "produces a module that extends #{described_class.name}" do
        expect(client).to be_a Module
        expect(client).to be_kind_of described_class
      end

      it "knows it's broker" do
        expect(client.broker_name).to eq(broker_name)
        expect(client.broker).to be(broker)
      end

      context "when the resulting module is used as an included module" do
        subject! do
          clz = Class.new
          clz.send :include, client
          clz.new
        end
        it_behaves_like "a Client"
      end

      context "when the resulting module is used directly" do
        it_behaves_like "a Client" do
          subject! { client }
        end
      end
    end

    describe ".[]" do
      it "grabs the client for the given broker" do
        expected = double("client")
        allow(Broker).to receive(:client).with(:test_broker).and_return(expected)
        expect(described_class[:test_broker]).to be expected
      end
    end
  end
end
