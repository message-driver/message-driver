require 'spec_helper'

describe MessageDriver::Broker do
  subject { described_class }

  describe ".configure" do
    it "raises an error if you don't specify an adapter" do
      expect {
        subject.configure({})
      }.to raise_error(/must specify an adapter/)
    end

    it "if you provide an adapter instance, it uses that one" do
      adapter = MessageDriver::Adapter::InMemory.new({})

      subject.configure(adapter: adapter)
      expect(subject.adapter).to be adapter
    end

    it "if you provide an adapter class, it will instansiate it" do
      adapter = MessageDriver::Adapter::InMemory

      subject.configure(adapter: adapter)
      expect(subject.adapter).to be_a adapter
    end

    it "if you provide a symbol, it will try to look up the adapter class" do
      adapter = :bunny

      subject.configure(adapter: adapter)
      expect(subject.adapter).to be_a MessageDriver::Adapter::Bunny
    end

    it "raises and error if you don't provide a MessageDriver::Adapter::Base" do
      adapter = Hash.new

      expect {
        subject.configure(adapter: adapter)
      }.to raise_error(/adapter must be a MessageDriver::Adapter::Base/)
    end
  end
end
