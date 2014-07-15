require 'spec_helper'

module MessageDriver::Adapters
  describe Base do
    class TestAdapter < Base
      def initialize(_configuration)
      end
    end
    subject(:adapter) { TestAdapter.new({}) }

    describe '#new_context' do
      it 'raises an error' do
        expect do
          subject.new_context
        end.to raise_error 'Must be implemented in subclass'
      end
    end

    describe ContextBase do
      class TestContext < ContextBase
      end
      subject(:adapter_context) { TestContext.new(adapter) }

      it_behaves_like 'an adapter context'
      it_behaves_like 'transactions are not supported'
      it_behaves_like 'client acks are not supported'
      it_behaves_like 'subscriptions are not supported'

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
