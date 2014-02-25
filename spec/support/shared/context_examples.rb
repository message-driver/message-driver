shared_examples "an adapter context" do
  it { should be_a MessageDriver::Adapters::ContextBase }

  its(:adapter) { should be adapter }

  it "is initially valid" do
    should be_valid
  end

  describe "#invalidate" do
    it "causes the context to become invalid" do
      subject.invalidate
      expect(subject).to_not be_valid
    end
  end
end
