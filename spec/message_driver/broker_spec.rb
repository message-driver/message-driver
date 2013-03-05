require 'spec_helper'

module MessageDriver
  describe Broker do
    subject { described_class }

    describe ".configure" do
      it "raises an error if you don't specify an adapter" do
        expect {
          subject.configure({})
        }.to raise_error(/must specify an adapter/)
      end

      it "if you provide an adapter instance, it uses that one" do
        adapter = Adapters::InMemoryAdapter.new({})

        subject.configure(adapter: adapter)
        expect(subject.adapter).to be adapter
      end

      it "if you provide an adapter class, it will instansiate it" do
        adapter = Adapters::InMemoryAdapter

        subject.configure(adapter: adapter)
        expect(subject.adapter).to be_a adapter
      end

      it "if you provide a symbol, it will try to look up the adapter class" do
        adapter = :in_memory

        subject.configure(adapter: adapter)
        expect(subject.adapter).to be_a Adapters::InMemoryAdapter
      end

      it "raises and error if you don't provide a MessageDriver::Adapters::Base" do
        adapter = Hash.new

        expect {
          subject.configure(adapter: adapter)
        }.to raise_error(/adapter must be a MessageDriver::Adapters::Base/)
      end
    end

    describe ".configuration" do
      it "returns the configuration hash you passed to .configure" do
        config = {adapter: :in_memory, foo: :bar, baz: :boz}
        subject.configure(config)
        expect(subject.configuration).to be config
      end
    end
  end
end
