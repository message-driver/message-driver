require 'message_driver'

require File.join(File.dirname(__FILE__), '..', 'test_lib', 'broker_config')

Dir["./spec/support/**/*.rb"].sort.each {|f| require f}

RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
  c.order = 'random'
  c.filter_run :focus

  c.reporter.message("Acceptance Tests running with broker config: #{BrokerConfig.config}")

  #c.filter_run_excluding :no_ci if ENV['CI']=='true' && ENV['ADAPTER'] && ENV['ADAPTER'].starts_with?('bunny')
  if c.inclusion_filter[:all_adapters] == true
    BrokerConfig.unconfigured_adapters.each do |a|
      c.filter_run_excluding a
    end
    c.filter_run_including BrokerConfig.current_adapter
  else
    c.run_all_when_everything_filtered = true
  end
end
