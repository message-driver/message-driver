module AcceptanceMethods
  def _broker_config
    adapter_file = File.expand_path("../../../.adapter_under_test", __FILE__)
    adapter = ENV['ADAPTER_UNDER_TEST'] || (File.exist?(adapter_file) && File.read(adapter_file).chomp)
    case adapter
    when 'bunny'
      {adapter: :bunny}
    when 'in_memory'
      {adapter: :in_memory}
    else
      {adapter: :in_memory}
    end
  end
end

module AcceptanceContext
  include AcceptanceMethods

  def self.included(base)
    base.class_eval do
      before do
        MessageDriver.configure(_broker_config)
      end

      after do
        MessageDriver.stop
      end
    end
  end
end

RSpec.configure do |c|
  include AcceptanceMethods

  c.include AcceptanceContext, turnip: true

  c.reporter.message("Acceptance Tests running with broker config: #{_broker_config}")
end
