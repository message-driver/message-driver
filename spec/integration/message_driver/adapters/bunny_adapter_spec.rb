require 'spec_helper'

require 'message_driver/adapters/bunny_adapter'

module MessageDriver::Adapters
  describe BunnyAdapter, :bunny, type: :integration do

    let(:valid_connection_attrs) { BrokerConfig.config }

    describe "#initialize" do
      context "differing bunny versions" do
        shared_examples "raises an error" do
          it "raises an error" do
            stub_const("Bunny::VERSION", version)
            expect {
              described_class.new(valid_connection_attrs)
            }.to raise_error MessageDriver::Error, "bunny 0.9.0.pre7 or later is required for the bunny adapter"
          end
        end
        shared_examples "doesn't raise an error" do
          it "doesn't raise an an error" do
            stub_const("Bunny::VERSION", version)
            adapter = nil
            expect {
              adapter = described_class.new(valid_connection_attrs)
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

      it "connects to the rabbit broker lazily" do
        adapter = described_class.new(valid_connection_attrs)

        expect(adapter.connection(false)).to_not be_open
      end

      it "forces bunny into non-threaded mode", pending: "needs to be re-evaluated. we might want to disable automatic recovery instead" do
        #FIXME can be changed once ruby-amqp/bunny#112 is fixed
        adapter = described_class.new(valid_connection_attrs)
        expect(adapter.connection(false).threaded).to be_false

        adapter = described_class.new(valid_connection_attrs.merge(threaded: true))
        expect(adapter.connection(false).threaded).to be_false
      end
    end

    shared_context "a connected bunny adapter" do
      subject(:adapter) { described_class.new(valid_connection_attrs) }
      let(:connection) { adapter.connection }

      before do
        MessageDriver::Broker.configure(adapter: adapter)
      end

      after do
        adapter.stop
      end
    end

    shared_context "with a queue" do
      include_context "a connected bunny adapter"

      let(:channel) { connection.create_channel }
      let(:tmp_queue_name) { "my_temp_queue" }
      let(:tmp_queue) { channel.queue(tmp_queue_name, exclusive: true) }
    end

    describe "#new_context" do
      include_context "a connected bunny adapter"

      it "returns a BunnyAdapter::BunnyContext" do
        expect(subject.new_context).to be_a BunnyAdapter::BunnyContext
      end
    end

    describe BunnyAdapter::BunnyContext do
      include_context "a connected bunny adapter"
      subject(:adapter_context) { adapter.new_context }

      include_examples "supports transactions"

      describe "#pop_message" do
        include_context "with a queue"
        it "needs some real tests"
      end

      it_behaves_like "an adapter context"

      describe "#invalidate" do
        it "closes the channel" do
          subject.with_channel(false) do |ch|
            expect(ch).to be_open
          end
          subject.invalidate
          expect(subject.instance_variable_get(:@channel)).to be_closed
        end
      end

      describe "#create_destination" do

        context "with defaults" do
          context "the resulting destination" do
            let(:dest_name) { "my_dest" }
            subject(:result) { adapter_context.create_destination(dest_name, exclusive: true) }

            it { should be_a BunnyAdapter::QueueDestination }
          end
        end

        context "the type is queue" do
          context "and there is no destination name given" do
            subject(:destination) { adapter_context.create_destination("", type: :queue, exclusive: true) }
            it { should be_a BunnyAdapter::QueueDestination }
            its(:name) { should be_a String }
            its(:name) { should_not be_empty }
          end
          context "the resulting destination" do
            let(:dest_name) { "my_dest" }
            subject(:destination) { adapter_context.create_destination(dest_name, type: :queue, exclusive: true) }
            before do
              destination
            end

            it { should be_a BunnyAdapter::QueueDestination }
            its(:name) { should be_a String }
            its(:name) { should eq(dest_name) }

            include_examples "supports #message_count"

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
            context "publishing a message" do
              let(:body) { "Testing the QueueDestination" }
              let(:headers) { {"foo" => "bar"} }
              let(:properties) { {persistent: false} }
              before do
                subject.publish(body, headers, properties)
              end
              it "publishes via the default exchange" do
                msg = subject.pop_message
                expect(msg.body).to eq(body)
                expect(msg.headers).to eq(headers)
                expect(msg.properties[:delivery_mode]).to eq(1)
                expect(msg.delivery_info.exchange).to eq("")
                expect(msg.delivery_info.routing_key).to eq(subject.name)
              end
            end
            it_behaves_like "a destination"
          end
          context "and bindings are provided" do
            let(:dest_name) { "binding_test_queue" }
            let(:exchange) { adapter_context.create_destination("amq.direct", type: :exchange) }

            it "raises an exception if you don't provide a source" do
              expect {
                adapter_context.create_destination("bad_bind_queue", type: :queue, exclusive: true, bindings: [{args: {routing_key: "test_exchange_bind"}}])
              }.to raise_error MessageDriver::Error, /must provide a source/
            end

            it "routes message to the queue through the exchange" do
              destination = adapter_context.create_destination(dest_name, type: :queue, exclusive: true, bindings: [{source: "amq.direct", args: {routing_key: "test_queue_bind"}}])
              exchange.publish("test queue bindings", {}, {routing_key: "test_queue_bind"})
              message = destination.pop_message
              expect(message).to_not be_nil
              expect(message.body).to eq("test queue bindings")
            end
          end

          context "we are not yet connected to the broker and :no_declare is provided" do
            it "doesn't cause a connection to the broker" do
              connection.stop
              adapter_context.create_destination("test_queue", no_declare: true, type: :queue, exclusive: true)
              expect(adapter.connection(false)).to_not be_open
            end

            context "with a server-named queue" do
              it "raises an error" do
                expect {
                  adapter_context.create_destination("", no_declare: true, type: :queue, exclusive: true)
                }.to raise_error MessageDriver::Error, "server-named queues must be declared, but you provided :no_declare => true"
              end
            end

            context "with bindings" do
              it "raises an error" do
                expect {
                  adapter_context.create_destination("tmp_queue", no_declare: true, bindings: [{source: "amq.fanout"}], type: :queue, exclusive: true)
                }.to raise_error MessageDriver::Error, "queues with bindings must be declared, but you provided :no_declare => true"
              end
            end
          end
        end

        context "the type is exchange" do
          context "the resulting destination" do
            let(:dest_name) { "my_dest" }
            subject(:destination) { adapter_context.create_destination(dest_name, type: :exchange) }

            it { should be_a BunnyAdapter::ExchangeDestination }
            include_examples "doesn't support #message_count"

            it "strips off the type so it isn't set on the destination" do
              expect(subject.dest_options).to_not have_key :type
            end

            it "raises an error when pop_message is called" do
              expect {
                subject.pop_message(dest_name)
              }.to raise_error MessageDriver::Error, "You can't pop a message off an exchange"
            end

            context "publishing a message" do
              let(:body) { "Testing the ExchangeDestination" }
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
                subject.publish(body, headers, properties)
              end

              it "publishes to the specified exchange" do
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

          context "declaring an exchange on the broker" do
            let(:dest_name) { "my.cool.exchange" }

            it "creates the exchange if you include 'declare' in the options" do
              exchange = adapter_context.create_destination(dest_name, type: :exchange, declare: {type: :fanout, auto_delete: true})
              queue = adapter_context.create_destination("", type: :queue, exclusive: true, bindings: [{source: dest_name}])
              exchange.publish("test declaring exchange")
              message = queue.pop_message
              expect(message).to_not be_nil
              expect(message.body).to eq("test declaring exchange")
            end

            it "raises an error if you don't provide a type" do
              expect {
                adapter_context.create_destination(dest_name, type: :exchange, declare: {auto_delete: true})
              }.to raise_error MessageDriver::Error, /you must provide a valid exchange type/
            end

          end

          context "and bindings are provided" do
            let(:dest_name) { "binding_exchange_queue" }
            let(:exchange) { adapter_context.create_destination("amq.direct", type: :exchange) }

            it "raises an exception if you don't provide a source" do
              expect {
                adapter_context.create_destination("amq.fanout", type: :exchange, bindings: [{args: {routing_key: "test_exchange_bind"}}])
              }.to raise_error MessageDriver::Error, /must provide a source/
            end

            it "routes message to the queue through the exchange" do
              adapter_context.create_destination("amq.fanout", type: :exchange, bindings: [{source: "amq.direct", args: {routing_key: "test_exchange_bind"}}])
              destination = adapter_context.create_destination(dest_name, type: :queue, exclusive: true, bindings: [{source: "amq.fanout"}])
              exchange.publish("test exchange bindings", {}, {routing_key: "test_exchange_bind"})
              message = destination.pop_message
              expect(message).to_not be_nil
              expect(message.body).to eq("test exchange bindings")
            end
          end

          context "we are not yet connected to the broker" do
            it "doesn't cause a connection to the broker" do
              connection.stop
              adapter_context.create_destination("amq.fanout", type: :exchange)
              expect(adapter.connection(false)).to_not be_open
            end
          end
        end

        context "the type is invalid" do
          it "raises in an error" do
            expect {
              adapter_context.create_destination("my_dest", type: :foo_bar)
            }.to raise_error MessageDriver::Error, "invalid destination type #{:foo_bar}"
          end
        end
      end
    end
  end
end
