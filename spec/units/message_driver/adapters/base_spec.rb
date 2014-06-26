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
        expect {
          subject.new_context
        }.to raise_error 'Must be implemented in subclass'
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
          expect {
            subject.create_destination('foo')
          }.to raise_error 'Must be implemented in subclass'
        end
      end

      describe '#publish' do
        it 'raises an error' do
          expect {
            subject.publish(:destination, {foo: 'bar'})
          }.to raise_error 'Must be implemented in subclass'
        end
      end

      describe '#pop_message' do
        it 'raises an error' do
          expect {
            subject.pop_message(:destination)
          }.to raise_error 'Must be implemented in subclass'
        end
      end

    end
  end
end
