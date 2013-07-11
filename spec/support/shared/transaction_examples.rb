shared_examples "transactions are not supported" do
  describe "#supports_transactions?" do
    it "returns false" do
      expect(subject.supports_transactions?).to eq(false)
    end
  end
end

shared_examples "transactions are supported" do
  describe "#supports_transactions?" do
    it "returns true" do
      expect(subject.supports_transactions?).to eq(true)
    end
  end

  it { should respond_to :begin_transaction }
  it { should respond_to :commit_transaction }
  it { should respond_to :rollback_transaction }
  it { should respond_to :in_transaction? }

  describe "#in_transaction?" do
    it "returns false if you aren't in a transaction" do
      expect(subject.in_transaction?).to eq(false)
    end
  end

  it "raises a MessageDriver::TransactionError error if you begin two transactions" do
    subject.begin_transaction
    expect {
      subject.begin_transaction
    }.to raise_error MessageDriver::TransactionError
  end
  it "raises a MessageDriver::TransactionError error if you commit outside of a transaction" do
    expect {
      subject.commit_transaction
    }.to raise_error MessageDriver::TransactionError
  end
  it "raises a MessageDriver::TransactionError error if you rollback outside of a transaction" do
    expect {
      subject.rollback_transaction
    }.to raise_error MessageDriver::TransactionError
  end
end
