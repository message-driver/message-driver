module FirewallHelper
  def self.port
    BrokerConfig.current_adapter_port
  end

  COMMANDS = {
    darwin: {
      setup: [
        'lunchy stop rabbit'
      ],
      teardown: [
        'lunchy start rabbit'
      ]
    },
    linux: {
      setup: [
        'sudo service rabbitmq-server stop'
      ],
      teardown: [
        'sudo service rabbitmq-server start'
      ]
    }
  }

  def block_broker_port
    run_commands(:setup)
    @firewall_rule_set = true
  end

  def unblock_broker_port
    run_commands(:teardown) if @firewall_rule_set
    @firewall_rule_set = false
  end

  def run_commands(step)
    COMMANDS[os][step].each do |cmd|
      result = system(cmd)
      fail "command `#{cmd}` failed!" unless result
    end
  end

  def os
    if darwin?
      :darwin
    else
      :linux
    end
  end

  def darwin?
    system('uname | grep Darwin')
  end
end

World(FirewallHelper)
