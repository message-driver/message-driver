require 'message_driver'

Dir["./spec/support/**/*.rb"].sort.each {|f| require f}
Dir["./spec/acceptance/steps/**/*_steps.rb"].sort.each {|f| require f}

Turnip.type = :integration

RSpec.configure do |c|
  include AcceptanceMethods

  c.treat_symbols_as_metadata_keys_with_true_values = true
  c.order = 'random'
  c.filter_run :focus
  c.run_all_when_everything_filtered = true

  c.include AcceptanceContext, turnip: true

  broker_config = _broker_config
  c.reporter.message("Acceptance Tests running with broker config: #{broker_config}")

  if c.inclusion_filter[:type] == "integration"
    %w(in_memory bunny).map(&:to_sym).each do |a|
      c.filter_run_excluding a if a != broker_config[:adapter]
    end
  end
end
