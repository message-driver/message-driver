require 'message_driver'

def _broker_config
  adapter_file = File.expand_path("../../../.adapter_under_test", __FILE__)
  adapter = ENV['ADAPTER'] || (File.exist?(adapter_file) && File.read(adapter_file).chomp)
  case adapter
  when 'bunny'
    {
      adapter: :bunny,
      vhost: 'message-driver-test'
    }
  when 'in_memory'
    {adapter: :in_memory}
  else
    {adapter: :in_memory}
  end
end

Before do
  MessageDriver.configure(_broker_config)
end

After do
  MessageDriver.stop
end
