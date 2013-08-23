module BrokerConfigHelper
  def broker_config
    BrokerConfig.config.merge(@config)
  end

  def reset_broker_config
    @config = {}
  end

  def scenario_config
    @config
  end
end

Before do
  reset_broker_config
end

World(BrokerConfigHelper)
