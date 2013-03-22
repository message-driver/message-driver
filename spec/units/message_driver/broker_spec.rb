require 'spec_helper'
require 'message_driver/adapters/in_memory_adapter'

module MessageDriver
  describe Broker do
    subject(:broker) { described_class.new(adapter: :in_memory) }

    describe ".configure" do
      it "calls new, passing in the options and saves the instance" do
        options = {foo: :bar}
        result = stub(described_class)
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

    describe "#publish" do
      it "needs some real tests"

      context "when the destination can't be found" do
        it "raises an error"
      end
    end
    describe "#pop_message" do
      it "needs some real tests"

      context "when the destination can't be found" do
        it "raises an error"
      end
    end

    describe "#destination" do
      it "needs some real tests"
    end

    describe "#dynamic_destination" do
      it "returns the destination" do
        destination = broker.dynamic_destination("my_queue", exclusive: true)
        expect(destination).to be_a MessageDriver::Destination::Base
      end
      it "doesn't save the destination" do
        destination = nil
        expect {
          destination = broker.dynamic_destination("my_queue", exclusive: true)
        }.to_not change{broker.destinations.size}
        expect(broker.destinations.values).to_not include(destination)
      end
    end
  end
end
