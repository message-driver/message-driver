require 'spec_helper'

require 'message_driver/adapters/bunny_adapter'

module MessageDriver::Adapters
  describe BunnyAdapter, :bunny, type: :integration do

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

      after do
        connection.close
      end
    end

    shared_context "with a queue" do
      include_context "a connected adapter"

      let(:channel) { connection.create_channel }
      let(:tmp_queue_name) { "my_temp_queue" }
      let!(:tmp_queue) { channel.queue(tmp_queue_name, exclusive: true) }
    end

    describe "#pop_message" do
      include_context "with a queue"
      it "needs some real tests"
    end

    describe "#create_destination" do
      include_context "a connected adapter"

      context "with defaults" do
        context "the resulting destination" do
          let(:dest_name) { "my_dest" }
          let(:result) { adapter.create_destination(dest_name, exclusive: true) }
          subject { result }

          it { should be_a BunnyAdapter::QueueDestination }
        end
      end

      context "the type is queue" do
        context "the resulting destination" do
          let(:dest_name) { "my_dest" }
          let!(:result) { adapter.create_destination(dest_name, type: :queue, exclusive: true) }
          subject { result }

          it { should be_a BunnyAdapter::QueueDestination }

          it "strips off the type so it isn't set on the destination" do
            expect(subject.dest_options).to_not have_key :type
          end
          it "ensures the queue is declared" do
            expect {
              connection.with_channel do |ch|
                ch.queue(dest_name, passive: true)
              end
            }.to_not raise_error
          end
          context "sending a message" do
            let(:body) { "Testing the QueueDestination" }
            let(:headers) { {"foo" => "bar"} }
            let(:properties) { {persistent: false} }
            before do
              subject.send_message(body, headers, properties)
            end
            it "sends via the default exchange" do
              msg = subject.pop_message
              expect(msg.body).to eq(body)
              expect(msg.headers).to eq(headers)
              expect(msg.properties[:delivery_mode]).to eq(1)
              expect(msg.delivery_info.exchange).to eq("")
              expect(msg.delivery_info.routing_key).to eq(subject.name)
            end
          end
          it_behaves_like "a destination" do
            let(:destination) { result }
          end
        end
      end

      context "the type is exchange" do
        context "the resulting destination" do
          let(:dest_name) { "my_dest" }
          let(:result) { adapter.create_destination(dest_name, type: :exchange) }
          subject { result }

          it { should be_a BunnyAdapter::ExchangeDestination }
          it "strips off the type so it isn't set on the destination" do
            expect(subject.dest_options).to_not have_key :type
          end
          it "raises an error when pop_message is called" do
            expect {
              subject.pop_message(dest_name)
            }.to raise_error "You can't pop a message off an exchange"
          end
          context "sending a message" do
            let(:body) { "Testing the QueueDestination" }
            let(:headers) { {"foo" => "bar"} }
            let(:properties) { {persistent: false} }
            before { connection.with_channel { |ch| ch.fanout(dest_name, auto_delete: true) } }
            let!(:queue) do
              q = nil
              connection.with_channel do |ch|
                q = ch.queue("", exclusive: true)
                q.bind(dest_name)
              end
              q
            end
            before do
              subject.send_message(body, headers, properties)
            end
            it "sends to the specified exchange" do
              connection.with_channel do |ch|
                q = ch.queue(queue.name, passive: true)
                msg = q.pop
                expect(msg[2]).to eq(body)
                expect(msg[0].exchange).to eq(dest_name)
                expect(msg[1][:headers]).to eq(headers)
                expect(msg[1][:delivery_mode]).to eq(1)
              end
            end
          end
        end
      end

      context "the type is invalid" do
        it "raises in an error" do
          expect {
            adapter.create_destination("my_dest", type: :foo_bar)
          }.to raise_error "invalid destination type #{:foo_bar}"
        end
      end
    end
  end
end
