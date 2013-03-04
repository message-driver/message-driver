require 'spec_helper'

describe MessageDriver::Broker do
  subject { described_class }

  describe ".configure" do
    it "creates an InMemory adapter if you don't specify one" do
      subject.configure

      expect(subject.adapter).to be_a MessageDriver::Adapter::InMemory
    end

    it "if you provide an adapter instance, it uses that one" do
      adapter = MessageDriver::Adapter::Base.new

      subject.configure(adapter: adapter)
      expect(subject.adapter).to be adapter
    end

    it "if you provide an adapter class, it will instansiate it" do
      adapter = MessageDriver::Adapter::Base.new

      subject.configure(adapter: adapter)
      expect(subject.adapter).to be adapter
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
