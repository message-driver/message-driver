require 'spec_helper'

require 'message_driver/adapters/stomp_adapter'

module MessageDriver::Adapters
  describe StompAdapter, :stomp, type: :integration do

    let(:valid_connection_attrs) { BrokerConfig.config }

    describe "#initialize" do
      let(:connection_attrs) { valid_connection_attrs }

      context "differing stomp versions" do
        shared_examples "raises a stomp error" do
          it "raises an error" do
            stub_const("Stomp::Version::STRING", version)
            expect {
              described_class.new(connection_attrs)
            }.to raise_error MessageDriver::Exception, "stomp 1.2.9 or a later version of the 1.2.x series is required for the stomp adapter"
          end
        end
        shared_examples "doesn't raise a stomp error" do
          it "doesn't raise an an error" do
            stub_const("Stomp::Version::STRING", version)
            adapter = nil
            expect {
              adapter = described_class.new(connection_attrs)
            }.to_not raise_error
          end
        end
        %w(1.1.0 1.2.8 1.3.0).each do |v|
          context "stomp version #{v}" do
            let(:version) { v }
            include_examples "raises a stomp error"
          end
        end
        %w(1.2.9 1.2.11).each do |v|
          context "stomp version #{v}" do
            let(:version) { v }
            include_examples "doesn't raise a stomp error"
          end
        end
      end

      describe "the resulting config" do
        let(:connection_attrs) { {hosts: [{host: "my_host"}]} }
        subject(:config) { described_class.new(connection_attrs).config }

        its([:connect_headers]) { should eq(:"accept-version" => "1.1,1.2") }
        its([:hosts]) { should eq(connection_attrs[:hosts]) }

        context "when vhost is specified" do
          let(:connection_attrs) { {hosts: [{host: "my_host"}], vhost: "my_vhost"} }

          it { should_not have_key(:vhost) }
          its([:connect_headers]) { should eq(:"accept-version" => "1.1,1.2", :"host" => "my_vhost") }
        end

        context "when there are things in the connect_headers" do
          let(:connection_attrs) { {hosts: [{host: "my_host"}], connect_headers: {"foo" => "bar"}} }

          its([:connect_headers]) { should eq(:"accept-version" => "1.1,1.2", "foo" => "bar") }

          context "and accept-version is one of the parameters" do
            let(:connection_attrs) { {hosts: [{host: "my_host"}], connect_headers: {"foo" => "bar", :"accept-version" => "foo!"}} }

            its([:connect_headers]) { should eq(:"accept-version" => "1.1,1.2", "foo" => "bar") }
          end
        end
      end
    end

    shared_context "a connected stomp adapter" do
      let(:adapter) { described_class.new(valid_connection_attrs) }
      let(:connection) { adapter.connection }

      after do
        connection.disconnect
      end
    end

    describe "#create_destination" do
      include_context "a connected stomp adapter"

      context "the resulting destination" do
        let(:dest_name) { "/queue/stomp_destination_spec" }
        subject(:destination) { adapter.create_destination(dest_name) }

        it_behaves_like "a destination"
        include_examples "doesn't support #message_count"

        describe "pop_message" do
          context "when there is a message on the queue" do
            let(:body) { "Testing stomp pop_message" }
            before do
              destination.publish(body)
            end

            it "returns the message" do
              msg = destination.pop_message
              expect(msg).to be_a MessageDriver::Adapters::StompAdapter::Message
              expect(msg.body).to eq(body)
            end
          end

          context "when the queue is empty" do
            it "returns nil" do
              msg = destination.pop_message
              expect(msg).to be_nil
            end
          end
        end
      end
    end
  end
end
