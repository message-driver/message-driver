class BrokerConfig
  class << self
    def config
      adapter_file = File.expand_path("../../.adapter_under_test", __FILE__)
      @adapter, @version = (ENV['ADAPTER'] || (File.exist?(adapter_file) ? File.read(adapter_file).chomp : "")).split(":")
      case @adapter
      when 'bunny'
        {
          adapter: :bunny,
          vhost: 'message-driver-test',
          continuation_timeout: 10000
        }
      when 'in_memory'
        {adapter: :in_memory}
      when 'stomp'
        {
          adapter: :stomp,
          vhost: 'message-driver-test',
          hosts: [{host: 'localhost', login: 'guest', passcode: 'guest'}],
          reliable: false,
          max_reconnect_attempts: 1
        }
      else
        {adapter: :in_memory}
      end
    end

    def all_adapters
      %w(in_memory bunny stomp)
    end

    def current_adapter
      config[:adapter]
    end

    def adapter_version
      config unless @version
      @version
    end

    def unconfigured_adapters
      all_adapters - [current_adapter]
    end

    def current_adapter_port
      case current_adapter
      when :bunny
        5672
      when :stomp
        61613
      else
        nil
      end
    end
  end
end
