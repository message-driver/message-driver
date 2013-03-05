require 'message_driver'

Dir["./spec/support/**/*.rb"].sort.each {|f| require f}

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.order = 'random'

  if defined?(Turnip)
    config.filter_run :turnip
    config.filter_run :integration
    %w(in_memory bunny).each do |a|
      config.filter_run_excluding a.to_sym unless a.to_sym == MessageDriver::Broker.configuration[:adapter]
    end
  else
    config.filter_run :focus
    config.filter_run_excluding :integration
    config.run_all_when_everything_filtered = true
  end
end
