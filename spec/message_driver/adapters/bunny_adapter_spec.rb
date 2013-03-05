require 'spec_helper'

require 'message_driver/adapters/bunny_adapter'

module MessageDriver::Adapters
  describe BunnyAdapter, :bunny, :integration do

    let(:valid_connection_attrs) { {
      vhost: 'message-driver-test',
      threaded: false
    } }

    describe "#initialize" do
      context "differing bunny versions" do
        shared_examples "raises an error" do
          it "raises an error" do
            stub_const("Bunny::VERSION", version)
            expect {
              described_class.new({})
            }.to raise_error "bunny 0.9.0.pre7 or later is required for the bunny adapter"
          end
        end
        shared_examples "doesn't raise an error" do
          it "doesn't raise an an error" do
            stub_const("Bunny::VERSION", version)
            expect {
              described_class.new({})
            }.to_not raise_error
          end
        end
        %w(0.8.0 0.9.0.pre6).each do |v|
          context "bunny version #{v}" do
            let(:version) { v }
            include_examples "raises an error"
          end
        end
        %w(0.9.0.pre7 0.9.0.rc1 0.9.0 0.9.1).each do |v|
          context "bunny version #{v}" do
            let(:version) { v }
            include_examples "doesn't raise an error"
          end
        end
      end

      it "connects to the rabbit broker" do
        adapter = described_class.new(valid_connection_attrs)

        expect(adapter.connection).to be_a Bunny::Session
        expect(adapter.connection).to be_open
      end
    end

    shared_context "a connected adapter" do
      let!(:adapter) { described_class.new(valid_connection_attrs) }
      let(:connection) { adapter.connection }
      let(:channel) { connection.create_channel }
      let(:tmp_queue_name) { "my_temp_queue" }
      let!(:tmp_queue) { channel.queue(tmp_queue_name, exclusive: true) }

      after do
        connection.close
      end
    end

    describe "#send_message" do
      include_context "a connected adapter"
      let(:body) { "This is my message body!" }
      let(:headers) { {"foo" => "bar"} }
      let(:properties) { {persistent: false} }

      it "sends messages to the specified queue" do
        expect {
          adapter.send_message(tmp_queue_name, body, headers, properties)
        }.to change{tmp_queue.message_count}.from(0).to(1)

        actual = tmp_queue.pop

        expect(actual[2]).to eq(body)
        expect(actual[1][:headers]).to eq(headers)
        expect(actual[1][:delivery_mode]).to eq(1)
      end
    end

    #describe "#pop_message" do
      #include_context "a connected adapter"
    #end

    it_behaves_like "an adapter" do
      include_context "a connected adapter"
      let(:destination) { tmp_queue_name }
      let(:adapter) { described_class.new(valid_connection_attrs) }
    end

  end
end
