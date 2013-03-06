require 'message_driver'

Dir["./spec/support/**/*.rb"].sort.each {|f| require f}
Dir["./spec/acceptance/steps/**/*_steps.rb"].sort.each {|f| require f}

Turnip.type = :integration

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.order = 'random'

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

end
