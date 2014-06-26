require 'spec_helper'

require 'message_driver/adapters/stomp_adapter'

module MessageDriver::Adapters
  describe StompAdapter, :stomp, type: :integration do

    let(:valid_connection_attrs) { BrokerConfig.config }

    describe '#initialize' do
      let(:connection_attrs) { valid_connection_attrs }
      let(:broker) { double('broker') }

      context 'differing stomp versions' do
        shared_examples 'raises a stomp error' do
          it 'raises an error' do
            stub_const('Stomp::Version::STRING', version)
            expect {
              described_class.new(broker, connection_attrs)
            }.to raise_error MessageDriver::Error, 'stomp 1.3.1 or a later version of the 1.3.x series is required for the stomp adapter'
          end
        end
        shared_examples "doesn't raise a stomp error" do
          it "doesn't raise an an error" do
            stub_const('Stomp::Version::STRING', version)
            adapter = nil
            expect {
              adapter = described_class.new(broker, connection_attrs)
            }.to_not raise_error
          end
        end
        %w(1.1.0 1.2.9 1.3.0 1.4.0).each do |v|
          context "stomp version #{v}" do
            let(:version) { v }
            include_examples 'raises a stomp error'
          end
        end
        %w(1.3.1 1.3.5).each do |v|
          context "stomp version #{v}" do
            let(:version) { v }
            include_examples "doesn't raise a stomp error"
          end
        end
      end

      describe 'the resulting config' do
        let(:connection_attrs) { {hosts: [{host: 'my_host'}]} }
        subject(:config) { described_class.new(broker, connection_attrs).config }

        its([:connect_headers]) { should eq(:"accept-version" => '1.1,1.2') }
        its([:hosts]) { should eq(connection_attrs[:hosts]) }

        context 'when vhost is specified' do
          let(:connection_attrs) { {hosts: [{host: 'my_host'}], vhost: 'my_vhost'} }

          it { should_not have_key(:vhost) }
          its([:connect_headers]) { should eq(:"accept-version" => '1.1,1.2', :"host" => 'my_vhost') }
        end

        context 'when there are things in the connect_headers' do
          let(:connection_attrs) { {hosts: [{host: 'my_host'}], connect_headers: {'foo' => 'bar'}} }

          its([:connect_headers]) { should eq(:"accept-version" => '1.1,1.2', 'foo' => 'bar') }

          context 'and accept-version is one of the parameters' do
            let(:connection_attrs) { {hosts: [{host: 'my_host'}], connect_headers: {'foo' => 'bar', :"accept-version" => 'foo!'}} }

            its([:connect_headers]) { should eq(:"accept-version" => '1.1,1.2', 'foo' => 'bar') }
          end
        end
      end
    end

    shared_context 'a connected stomp adapter' do
      let(:broker) { MessageDriver::Broker.configure(valid_connection_attrs) }
      subject(:adapter) { broker.adapter }

      after do
        adapter.stop
      end
    end

    it_behaves_like 'an adapter' do
      include_context 'a connected stomp adapter'
    end

    describe '#new_context' do
      include_context 'a connected stomp adapter'

      it 'returns a StompAdapter::StompContext' do
        expect(adapter.new_context).to be_a StompAdapter::StompContext
      end
    end

    describe StompAdapter::StompContext do
      include_context 'a connected stomp adapter'
      subject(:adapter_context) { adapter.new_context }

      it_behaves_like 'an adapter context'
      it_behaves_like 'transactions are not supported'
      it_behaves_like 'client acks are not supported'
      it_behaves_like 'subscriptions are not supported'

      describe '#create_destination' do

        context 'the resulting destination' do
          let(:dest_name) { '/queue/stomp_destination_spec' }
          subject(:destination) { adapter_context.create_destination(dest_name) }

          it { should be_a StompAdapter::Destination }

          it_behaves_like 'a destination'
          include_examples "doesn't support #message_count"

          describe 'pop_message' do
            context 'when there is a message on the queue' do
              let(:body) { 'Testing stomp pop_message' }
              before do
                destination.publish(body)
              end

              it 'returns the message' do
                msg = destination.pop_message
                expect(msg).to be_a MessageDriver::Adapters::StompAdapter::Message
                expect(msg.body).to eq(body)
              end
            end

            context 'when the queue is empty' do
              it 'returns nil' do
                msg = destination.pop_message
                expect(msg).to be_nil
              end
            end
          end
        end
      end
    end
  end
end
