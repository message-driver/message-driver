module BrokerConfig
  def self.config
    adapter_file = File.expand_path("../../.adapter_under_test", __FILE__)
    adapter = ENV['ADAPTER'] || (File.exist?(adapter_file) && File.read(adapter_file).chomp)
    case adapter
    when 'bunny'
      {
        adapter: :bunny,
        vhost: 'message-driver-test'
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

  def self.all_adapters
    %w(in_memory bunny stomp)
  end

  def self.current_adapter
    config[:adapter]
  end

  def self.unconfigured_adapters
    all_adapters - current_adapter
  end
end
