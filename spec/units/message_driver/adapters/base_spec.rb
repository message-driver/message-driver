require 'spec_helper'

module MessageDriver
  module Adapters
    RSpec.describe Base do
      let(:spec_adapter_class) do
        Class.new(described_class) do
          def initialize; end
        end
      end
      subject(:adapter) { spec_adapter_class.new }

      describe '#new_context' do
        it 'raises an error' do
          expect do
            subject.new_context
          end.to raise_error 'Must be implemented in subclass'
        end
      end

      context 'with a test adapter' do
        subject(:adapter) { TestAdapter.new(nil, {}) }

        describe ContextBase do
          context 'with a test context subclass' do
            subject(:adapter_context) { TestContext.new(adapter) }

            it_behaves_like 'an adapter context'
            it_behaves_like 'transactions are not supported'
            it_behaves_like 'client acks are not supported'
            it_behaves_like 'subscriptions are not supported'
          end

          subject(:adapter_context) { ContextBase.new(adapter) }

          describe '#create_destination' do
            it 'raises an error' do
              expect do
                subject.create_destination('foo')
              end.to raise_error 'Must be implemented in subclass'
            end
          end

          describe '#publish' do
            it 'raises an error' do
              expect do
                subject.publish(:destination, foo: 'bar')
              end.to raise_error 'Must be implemented in subclass'
            end
          end

          describe '#pop_message' do
            it 'raises an error' do
              expect do
                subject.pop_message(:destination)
              end.to raise_error 'Must be implemented in subclass'
            end
          end
        end
      end
    end
  end
end
