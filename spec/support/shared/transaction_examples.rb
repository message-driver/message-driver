RSpec.shared_examples 'transactions are not supported' do
  describe '#supports_transactions?' do
    it 'returns false' do
      expect(subject.supports_transactions?).to eq(false)
    end
  end

  describe '#begin_transaction' do
    it 'raises an error' do
      expect do
        subject.begin_transaction
      end.to raise_error "transactions are not supported by #{subject.adapter.class}"
    end
  end

  describe '#commit_transaction' do
    it 'raises an error' do
      expect do
        subject.commit_transaction
      end.to raise_error "transactions are not supported by #{subject.adapter.class}"
    end
  end

  describe '#rollback_transaction' do
    it 'raises an error' do
      expect do
        subject.rollback_transaction
      end.to raise_error "transactions are not supported by #{subject.adapter.class}"
    end
  end

  it { is_expected.not_to override_method :handle_begin_transaction }
  it { is_expected.not_to override_method :handle_commit_transaction }
  it { is_expected.not_to override_method :handle_rollback_transaction }
end

RSpec.shared_examples 'transactions are supported' do
  describe '#supports_transactions?' do
    it 'returns true' do
      expect(subject.supports_transactions?).to eq(true)
    end
  end

  it { is_expected.to override_method :handle_begin_transaction }
  it { is_expected.not_to override_method :begin_transaction }
  it { is_expected.to override_method :handle_commit_transaction }
  it { is_expected.not_to override_method :commit_transaction }
  it { is_expected.to override_method :handle_rollback_transaction }
  it { is_expected.not_to override_method :rollback_transaction }
  it { is_expected.to override_method :in_transaction? }

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
