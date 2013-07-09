shared_examples "an adapter context" do
  it "is initially valid" do
    expect(subject).to be_valid
  end

  describe "#invalidate" do
    it "causes the context to become invalid" do
      subject.invalidate
      expect(subject).to_not be_valid
    end
  end
end
