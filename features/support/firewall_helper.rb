module FirewallHelper

  def self.port
    BrokerConfig.current_adapter_port
  end

  COMMANDS = {
    darwin: {
      setup: [
        "sudo ipfw add 02070 deny tcp from any to any #{port}"
      ],
      teardown: [
        "sudo ipfw delete 02070"
      ]
    },
    linux: {
      setup: [
        "sudo iptables -N block-rabbit",
        "sudo iptables -A block-rabbit -p tcp --dport #{port} -j DROP",
        "sudo iptables -A block-rabbit -p tcp --sport #{port} -j DROP",
        "sudo iptables -I INPUT -j block-rabbit",
        "sudo iptables -I OUTPUT -j block-rabbit"
      ],
      teardown: [
        "sudo iptables -D INPUT -j block-rabbit",
        "sudo iptables -D OUTPUT -j block-rabbit",
        "sudo iptables -F block-rabbit",
        "sudo iptables -X block-rabbit"
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
      raise "command `#{cmd}` failed!" unless result
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
    system("uname | grep Darwin")
  end
end

World(FirewallHelper)
