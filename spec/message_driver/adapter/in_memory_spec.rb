require 'spec_helper'

describe MessageDriver::Adapter::InMemory do
  let(:adapter) { described_class.new }
  it_behaves_like "an adapter"
end
