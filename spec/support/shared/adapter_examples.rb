shared_examples "an adapter" do
  describe "#new_context" do
    it "returns a MessageDriver::Adapters::ContextBase" do
      expect(subject.new_context).to be_a MessageDriver::Adapters::ContextBase
    end
  end

  describe "#stop" do
    it "invalidates all the adapter contexts" do
      ctx1 = subject.new_context
      ctx2 = subject.new_context
      subject.stop
      expect(ctx1).to_not be_valid
      expect(ctx2).to_not be_valid
    end
  end
end
