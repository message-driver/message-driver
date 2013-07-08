require 'spec_helper'
require 'message_driver/adapters/in_memory_adapter'

module MessageDriver
  describe Broker do
    subject(:broker) { described_class.new(adapter: :in_memory) }

    describe ".configure" do
      it "calls new, passing in the options and saves the instance" do
        options = {foo: :bar}
        result = double(described_class)
        described_class.should_receive(:new).with(options).and_return(result)

        described_class.configure(options)

        expect(described_class.instance).to be result
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
