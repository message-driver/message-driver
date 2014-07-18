RSpec.shared_examples 'transactions are not supported' do
  describe '#supports_transactions?' do
    it 'returns false' do
      expect(subject.supports_transactions?).to eq(false)
    end
  end
end

RSpec.shared_examples 'transactions are supported' do
  describe '#supports_transactions?' do
    it 'returns true' do
      expect(subject.supports_transactions?).to eq(true)
    end
  end

  it { is_expected.to respond_to :begin_transaction }
  it { is_expected.to respond_to :commit_transaction }
  it { is_expected.to respond_to :rollback_transaction }
  it { is_expected.to respond_to :in_transaction? }

  describe '#in_transaction?' do
    it "returns false if you aren't in a transaction" do
      expect(subject.in_transaction?).to eq(false)
    end
  end

  it 'raises a MessageDriver::TransactionError error if you begin two transactions' do
    subject.begin_transaction
    expect do
      subject.begin_transaction
    end.to raise_error MessageDriver::TransactionError
  end
  it 'raises a MessageDriver::TransactionError error if you commit outside of a transaction' do
    expect do
      subject.commit_transaction
    end.to raise_error MessageDriver::TransactionError
  end
  it 'raises a MessageDriver::TransactionError error if you rollback outside of a transaction' do
    expect do
      subject.rollback_transaction
    end.to raise_error MessageDriver::TransactionError
  end
end
