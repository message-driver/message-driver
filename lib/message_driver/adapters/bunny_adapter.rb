require 'bunny'
require 'bunny/session_patch'

module MessageDriver
  class Broker
    def bunny_adapter
      MessageDriver::Adapters::BunnyAdapter
    end
  end

  module Adapters
    class BunnyAdapter < Base
      NETWORK_ERRORS = [Bunny::TCPConnectionFailed, Bunny::ConnectionClosedError, Bunny::ConnectionLevelException, Bunny::NetworkErrorWrapper, Bunny::NetworkFailure, IOError].freeze

      class Message < MessageDriver::Message::Base
        attr_reader :delivery_info

        def initialize(ctx, delivery_info, properties, payload)
          super(ctx, payload, properties[:headers]||{}, properties)
          @delivery_info = delivery_info
        end

        def delivery_tag
          delivery_info.delivery_tag
        end

        def redelivered?
          delivery_info.redelivered?
        end
      end

      class Destination < MessageDriver::Destination::Base
        def publish_params(headers, properties)
          props = @message_props.merge(properties)
          props[:headers] = headers if headers
          [exchange_name, routing_key(properties), props]
        end

        def exchange_name
          @name
        end

        def routing_key(properties)
          properties[:routing_key]
        end
      end

      class QueueDestination < Destination
        def after_initialize(adapter_context)
          unless @dest_options[:no_declare]
            adapter_context.with_channel(false) do |ch|
              bunny_queue(ch, true)
            end
          else
            raise MessageDriver::Error, "server-named queues must be declared, but you provided :no_declare => true" if @name.empty?
            raise MessageDriver::Error, "queues with bindings must be declared, but you provided :no_declare => true" if @dest_options[:bindings]
          end
        end

        def bunny_queue(channel, initialize=false)
          queue = channel.queue(@name, @dest_options)
          if initialize
            @name = queue.name
            if bindings = @dest_options[:bindings]
              bindings.each do |bnd|
                raise MessageDriver::Error, "binding #{bnd.inspect} must provide a source!" unless bnd[:source]
                queue.bind(bnd[:source], bnd[:args]||{})
              end
            end
          end
          queue
        end

        def exchange_name
          ""
        end

        def routing_key(properties)
          @name
        end

        def message_count
          Client.current_adapter_context.with_channel(false) do |ch|
            ch.queue(@name, @dest_options.merge(passive: true)).message_count
          end
        end

        def purge
          Client.current_adapter_context.with_channel(false) do |ch|
            bunny_queue(ch).purge
          end
        end
      end

      class ExchangeDestination < Destination
        def after_initialize(adapter_context)
          if declare = @dest_options[:declare]
            adapter_context.with_channel(false) do |ch|
              type = declare.delete(:type)
              raise MessageDriver::Error, "you must provide a valid exchange type" unless type
              ch.exchange_declare(@name, type, declare)
            end
          end
          if bindings = @dest_options[:bindings]
            adapter_context.with_channel(false) do |ch|
              bindings.each do |bnd|
                raise MessageDriver::Error, "binding #{bnd.inspect} must provide a source!" unless bnd[:source]
                ch.exchange_bind(bnd[:source], @name, bnd[:args]||{})
              end
            end
          end
        end
      end

      class Subscription < Subscription::Base
        def start
          raise MessageDriver::Error, "subscriptions are only supported with QueueDestinations" unless destination.is_a? QueueDestination
          @sub_ctx = adapter.new_subscription_context(self)
          @error_handler = options[:error_handler]
          @ack_mode = case options[:ack]
                      when :auto, nil
                        :auto
                      when :manual
                        :manual
                      when :transactional
                        :transactional
                      else
                        raise MessageDriver::Error, "unrecognized :ack option #{options[:ack]}"
                      end
          start_subscription
        end

        def unsubscribe
          unless @bunny_consumer.nil?
            @bunny_consumer.cancel
            @bunny_consumer = nil
          end
          unless @sub_ctx.nil?
            @sub_ctx.invalidate(true)
            @sub_ctx = nil
          end
        end

        private
        def start_subscription
          @sub_ctx.with_channel do |ch|
            queue = destination.bunny_queue(@sub_ctx.channel)
            if options.has_key? :prefetch_size
              ch.prefetch(options[:prefetch_size])
            end
            @bunny_consumer = queue.subscribe(options.merge(manual_ack: true)) do |delivery_info, properties, payload|
              Client.with_adapter_context(@sub_ctx) do
                message = @sub_ctx.args_to_message(delivery_info, properties, payload)
                handle_message(message)
              end
            end
          end
        end

        def handle_message(message)
          begin
            case @ack_mode
            when :auto
              consumer.call(message)
              @sub_ctx.ack_message(message)
            when :manual
              consumer.call(message)
            when :transactional
              Client.with_message_transaction do
                consumer.call(message)
                @sub_ctx.ack_message(message)
              end
            end
          rescue => e
            if [:auto, :transactional].include? @ack_mode
              requeue = true
              if e.is_a?(DontRequeue) || (options[:retry_redelivered] == false && message.redelivered?)
                requeue = false
              end
              if @sub_ctx.valid?
                begin
                  @sub_ctx.nack_message(message, requeue: requeue)
                rescue => e
                  logger.error exception_to_str(e)
                end
              end
            end
            @error_handler.call(e, message) unless @error_handler.nil?
          end
        end
      end

      def initialize(config)
        validate_bunny_version
        @config = config
        @handle_connection_errors = config.fetch(:handle_connection_errors, true)
        initialize_connection
      end

      def connection(ensure_started=true)
        initialize_connection
        if ensure_started
          begin
            @connection.start
          rescue *NETWORK_ERRORS => e
            raise MessageDriver::ConnectionError.new(e.to_s, e)
          end
        end
        @connection
      end

      def stop
        begin
          super
          @connection.close if !@connection.nil? && @connection.open?
        rescue *NETWORK_ERRORS => e
          logger.error "error while attempting connection close\n#{exception_to_str(e)}"
        ensure
          conn = @connection
          @connection = nil
          conn.cleanup_threads unless conn.nil?
        end
      end

      def build_context
        BunnyContext.new(self)
      end

      def new_subscription_context(subscription)
        ctx = new_context
        ctx.channel = connection.create_channel
        ctx.subscription = subscription
        ctx
      end

      class BunnyContext < ContextBase
        attr_accessor :channel, :subscription

        def initialize(adapter)
          super(adapter)
          @is_transactional = false
          @rollback_only = false
          @need_channel_reset = false
          @in_transaction = false
        end

        def create_destination(name, dest_options={}, message_props={})
          dest = case type = dest_options.delete(:type)
          when :exchange
            ExchangeDestination.new(self.adapter, name, dest_options, message_props)
          when :queue, nil
            QueueDestination.new(self.adapter, name, dest_options, message_props)
          else
            raise MessageDriver::Error, "invalid destination type #{type}"
          end
          dest.after_initialize(self)
          dest
        end

        def supports_transactions?
          true
        end

        def begin_transaction(options={})
          raise MessageDriver::TransactionError, "you can't begin another transaction, you are already in one!" if in_transaction?
          unless is_transactional?
            with_channel(false) do |ch|
              ch.tx_select
            end
            @is_transactional = true
          end
          @in_transaction = true
        end

        def commit_transaction(channel_commit=false)
          raise MessageDriver::TransactionError, "you can't finish the transaction unless you already in one!" if !in_transaction? && !channel_commit
          begin
            if is_transactional? && valid? && !@need_channel_reset
              handle_errors do
                if @rollback_only
                  @channel.tx_rollback
                else
                  @channel.tx_commit
                end
              end
            end
          ensure
            @rollback_only = false
            @in_transaction = false
          end
        end

        def rollback_transaction
          @rollback_only = true
          commit_transaction
        end

        def is_transactional?
          @is_transactional
        end

        def in_transaction?
          @in_transaction
        end

        def publish(destination, body, headers={}, properties={})
          exchange, routing_key, props = *destination.publish_params(headers, properties)
          with_channel(true) do |ch|
            ch.basic_publish(body, exchange, routing_key, props)
          end
        end

        def pop_message(destination, options={})
          raise MessageDriver::Error, "You can't pop a message off an exchange" if destination.is_a? ExchangeDestination

          with_channel(false) do |ch|
            queue = ch.queue(destination.name, passive: true)

            message = queue.pop(ack: !!options[:client_ack])
            if message.nil? || message[0].nil?
              nil
            else
              args_to_message(*message)
            end
          end
        end

        def supports_client_acks?
          true
        end

        def ack_message(message, options={})
          with_channel(true) do |ch|
            ch.ack(message.delivery_tag)
          end
        end

        def nack_message(message, options={})
          requeue = options[:requeue].kind_of?(FalseClass) ? false : true
          with_channel(true) do |ch|
            ch.reject(message.delivery_tag, requeue)
          end
        end

        def supports_subscriptions?
          true
        end

        def subscribe(destination, options={}, &consumer)
          sub = Subscription.new(adapter, destination, consumer, options)
          sub.start
          sub
        end

        def invalidate(in_unsubscribe=false)
          super()
          unless @subscription.nil? || in_unsubscribe
            begin
              @subscription.unsubscribe if adapter.connection.open?
            rescue => e
              logger.debug "error trying to end subscription\n#{exception_to_str(e)}"
            end
          end
          unless @channel.nil?
            begin
              @channel.close if @channel.open? && adapter.connection.open?
            rescue => e
              logger.debug "error trying to close channel\n#{exception_to_str(e)}"
            ensure
              begin @channel.maybe_kill_consumer_work_pool! rescue nil; end
            end
          end
        end

        def handle_errors
          begin
            yield
          rescue Bunny::ChannelLevelException => e
            @need_channel_reset = true
            @rollback_only = true if in_transaction?
            if e.kind_of? Bunny::NotFound
              raise MessageDriver::QueueNotFound.new(e.to_s, e)
            else
              raise MessageDriver::WrappedError.new(e.to_s, e)
            end
          rescue Bunny::ChannelAlreadyClosed => e
            @need_channel_reset = true
            @rollback_only = true if in_transaction?
            raise MessageDriver::WrappedError.new(e.to_s, e)
          rescue *NETWORK_ERRORS => e
            @need_channel_reset = true
            @rollback_only = true if in_transaction?
            raise MessageDriver::ConnectionError.new(e.to_s, e)
          end
        end

        def with_channel(require_commit=true)
          raise MessageDriver::TransactionRollbackOnly if @rollback_only
          raise MessageDriver::Error, "oh nos!" if !valid?
          @channel = adapter.connection.create_channel if @channel.nil?
          reset_channel if @need_channel_reset
          handle_errors do
            result = yield @channel
            commit_transaction(true) if require_commit && is_transactional? && !in_transaction?
            result
          end
        end

        def args_to_message(delivery_info, properties, payload)
          Message.new(self, delivery_info, properties, payload)
        end

        private

        def reset_channel
          unless @channel.open?
            @channel = adapter.connection.create_channel
            @is_transactional = false
            @rollback_only = true if in_transaction?
          end
          @need_channel_reset = false
        end
      end

      private

      def log_errors
        begin
          yield
        rescue => e
          logger.error exception_to_str(e)
        end
      end

      def initialize_connection
        if @handle_connection_errors
          if @connection_thread.nil?
            #hi mom!
            @connection_thread = Thread.new do
              @connection = Bunny.new(@config)
              begin
                sleep
              rescue *NETWORK_ERRORS => e
                logger.error "error on connection\n#{exception_to_str(e)}"
                if @connection.automatically_recover?
                  sleep 0.1
                  unless @connection.recovering_from_network_failure?
                    stop
                  end
                else
                  stop
                end
                retry
              rescue => e
                logger.error "unhandled error in connection thread! #{exception_to_str(e)}"
              end
            end
            @connection_thread.abort_on_exception = true
            sleep 0.1
          end
          sleep 0.1 while @connection_thread.status != 'sleep'
        else
          @connection ||= Bunny.new(@config)
        end
      end

      def validate_bunny_version
        required = Gem::Requirement.create('>= 1.1.3')
        current = Gem::Version.create(Bunny::VERSION)
        unless required.satisfied_by? current
          raise MessageDriver::Error, "bunny 1.1.3 or later is required for the bunny adapter"
        end
      end
    end
  end
end
