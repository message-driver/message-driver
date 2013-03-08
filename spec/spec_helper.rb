require 'message_driver'

Dir["./spec/support/**/*.rb"].sort.each {|f| require f}
Dir["./spec/acceptance/steps/**/*_steps.rb"].sort.each {|f| require f}

Turnip.type = :integration

RSpec.configure do |c|
  include AcceptanceMethods

  c.treat_symbols_as_metadata_keys_with_true_values = true
  c.order = 'random'
  c.filter_run :focus

  c.include AcceptanceContext, turnip: true

  broker_config = _broker_config
  c.reporter.message("Acceptance Tests running with broker config: #{broker_config}")

  if c.inclusion_filter[:all_adapters] == true
    c.filter_run broker_config[:adapter]
  else
    c.run_all_when_everything_filtered = true
  end
end
