require 'spec_helper'
require 'message_driver/adapters/in_memory_adapter'

module MessageDriver
  describe Broker do
    let(:options) { { adapter: :in_memory } }
    before do
      described_class.configure(options)
    end
    subject(:broker) { described_class.broker }

    describe ".configure" do
      it "calls new, passing in the options and saves the instance" do
        options = {foo: :bar}
        result = double(described_class)
        described_class.should_receive(:new).with(described_class::DEFAULT_BROKER_NAME, options).and_return(result)

        described_class.configure(options)

        expect(described_class.broker).to be result
        expect(described_class.broker(described_class::DEFAULT_BROKER_NAME)).to be result
      end

      context "when configurating multiple brokers" do
        it "allows you to fetch each configured broker through .broker" do
          options1 = {foo: :bar}
          options2 = {bar: :baz}
          result1 = double("result1")
          result2 = double("result2")
          allow(described_class).to receive(:new).with(:result1, options1).and_return(result1)
          allow(described_class).to receive(:new).with(:result2, options2).and_return(result2)

          described_class.configure(:result1, options1)
          described_class.configure(:result2, options2)

          expect(described_class.broker(:result1)).to be(result1)
          expect(described_class.broker(:result2)).to be(result2)
        end
      end
    end

    describe "#logger" do
      it "returns the logger, which logs at the info level" do
        expect(subject.logger).to be_a Logger
        expect(subject.logger).to be_info
        expect(subject.logger).to_not be_debug
      end

      context "configuring the logger" do
        let(:logger) { double(Logger).as_null_object }
        let(:options) { { adapter: :in_memory, logger: logger } }

        it "returns the provided logger" do
          actual = subject.logger
          expect(actual).to be logger
        end
      end
    end

    describe "#initialize" do
      it "raises an error if you don't specify an adapter" do
        expect {
          described_class.new({})
        }.to raise_error(/must specify an adapter/)
      end

      it "if you provide an adapter instance, it uses that one" do
        adapter = Adapters::InMemoryAdapter.new({})

        instance = described_class.new(adapter: adapter)
        expect(instance.adapter).to be adapter
      end

      it "if you provide an adapter class, it will instansiate it" do
        adapter = Adapters::InMemoryAdapter

        instance = described_class.new(adapter: adapter)
        expect(instance.adapter).to be_a adapter
      end

      it "if you provide a symbol, it will try to look up the adapter class" do
        adapter = :in_memory

        instance = described_class.new(adapter: adapter)
        expect(instance.adapter).to be_a Adapters::InMemoryAdapter
      end

      it "raises and error if you don't provide a MessageDriver::Adapters::Base" do
        adapter = Hash.new

        expect {
          described_class.new(adapter: adapter)
        }.to raise_error(/adapter must be a MessageDriver::Adapters::Base/)
      end

      it "starts off with the adapter not stopped" do
        adapter = :in_memory

        instance = described_class.new(adapter: adapter)
        expect(instance).not_to be_stopped
      end

      it "has a default name of :default" do
        adapter = :in_memory

        instance = described_class.new(adapter: adapter)
        expect(instance.name).to eq(:default)
      end

      it "let's you override the name in the initializer" do
        adapter = :in_memory
        name = :my_vhost

        instance = described_class.new(name, adapter: adapter)
        expect(instance.name).to eq(name)
      end
    end

    describe "#stop" do
      let(:adapter) { broker.adapter }
      it "calls stop on the adapter" do
        allow(adapter).to receive(:stop).and_call_original

        subject.stop

        expect(adapter).to have_received(:stop)
      end

      it "marks the broker as stopped" do
        expect {
          subject.stop
        }.to change { subject.stopped? }.from(false).to(true)
      end

      it "invalidates the contexts" do
        my_ctx = double("context", invalidate: nil)
        adapter.contexts << my_ctx
        subject.stop
        expect(adapter.contexts).to be_empty
        expect(my_ctx).to have_received(:invalidate)
      end
    end

    describe "#restart" do
      let!(:original_adapter) { subject.adapter }
      before do
        allow(original_adapter).to receive(:stop).and_call_original
      end

      it "reconfigures the adapter" do
        expect {
          subject.restart
        }.to change { subject.adapter }
      end

      it "stops the adapter if it hasn't already been stopped" do
        subject.restart
        expect(original_adapter).to have_received(:stop).once
      end

      it "does not stop the adapter again if it has already been stopped" do
        expect(subject.adapter).to be original_adapter
        subject.stop
        expect {
          subject.restart
        }.to change { subject.stopped? }.from(true).to(false)
        expect(original_adapter).to have_received(:stop).once
      end
    end

    describe "#configuration" do
      it "returns the configuration hash you passed to .configure" do
        config = {adapter: :in_memory, foo: :bar, baz: :boz}
        instance = described_class.new(config)
        expect(instance.configuration).to be config
      end
    end

    describe "#destination" do
      it "returns the destination" do
        destination = broker.destination(:my_queue, "my_queue", exclusive: true)
        expect(destination).to be_a MessageDriver::Destination::Base
      end
    end

    describe "#find_destination" do
      it "finds the previously defined destination" do
        my_destination = broker.destination(:my_queue, "my_queue", exclusive: true)
        expect(broker.find_destination(:my_queue)).to be(my_destination)
      end

      context "when the destination can't be found" do
        let(:bad_dest_name) { :not_a_queue }
        it "raises a MessageDriver:NoSuchDestinationError" do
          expect {
            broker.find_destination(bad_dest_name)
          }.to raise_error(MessageDriver::NoSuchDestinationError, /#{bad_dest_name}/)
        end
      end
    end

    describe "#consumer" do
      let(:consumer_double) { lambda do |m| end }
      it "saves the provided consumer" do
        broker.consumer(:my_consumer, &consumer_double)
        expect(broker.consumers[:my_consumer]).to be(consumer_double)
      end

      context "when no consumer is provided" do
        it "raises an error" do
          expect {
            broker.consumer(:my_consumer)
          }.to raise_error(MessageDriver::Error, "you must provide a block")
        end
      end
    end

    describe "#find_consumer" do
      let(:consumer_double) { lambda do |m| end }
      it "finds the previously defined consumer" do
        my_consumer = broker.consumer(:my_consumer, &consumer_double)
        expect(broker.find_consumer(:my_consumer)).to be(my_consumer)
      end

      context "when the consumer can't be found" do
        let(:bad_consumer_name) { :not_a_queue }
        it "raises a MessageDriver:NoSuchConsumerError" do
          expect {
            broker.find_consumer(bad_consumer_name)
          }.to raise_error(MessageDriver::NoSuchConsumerError, /#{bad_consumer_name}/)
        end
      end
    end

    describe "#dynamic_destination" do
      it "returns the destination" do
        destination = broker.dynamic_destination("my_queue", exclusive: true)
        expect(destination).to be_a MessageDriver::Destination::Base
      end
    end

  end
end
