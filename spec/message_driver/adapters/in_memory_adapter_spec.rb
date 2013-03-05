require 'spec_helper'

require 'message_driver/adapters/in_memory_adapter'

module MessageDriver::Adapters
  describe InMemoryAdapter do
    let(:adapter) { described_class.new }
    it_behaves_like "an adapter"
  end
end
