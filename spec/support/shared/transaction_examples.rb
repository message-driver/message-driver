shared_examples "doesn't support transactions" do
  describe "#supports_transactions?" do
    it "returns false" do
      expect(subject.supports_transactions?).to eq(false)
    end
  end
end

shared_examples "supports transactions" do
  describe "#supports_transactions?" do
    it "returns true" do
      expect(subject.supports_transactions?).to eq(true)
    end
  end

  it { should respond_to :begin_transaction }
  it { should respond_to :commit_transaction }
  it { should respond_to :rollback_transaction }

  it "raises a MessageDriver::TransactionError error if you begin two transactions"
  it "raises a MessageDriver::TransactionError error if you commit outside of a transaction"
  it "raises a MessageDriver::TransactionError error if you rollback outside of a transaction"
end
