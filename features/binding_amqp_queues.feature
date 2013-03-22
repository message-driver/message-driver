@bunny
Feature: Binding amqp queues to exchanges through the destination API
  Background:
    Given The following broker configuration:
    """ruby
    MessageDriver::Broker.define do |b|
      b.destination :direct_exchange, "amq.direct", type: :exchange
    end
    """

  Scenario: Binding a queue to an exchange
    When I execute the following code:
    """ruby
    MessageDriver::Broker.define do |b|
      b.destination :my_queue, "my_queue", exclusive: true, bindings: [
        {source: "amq.direct", args: {routing_key: "test_binding"}},
        {source: "amq.direct", args: {routing_key: "spec_binding"}}
      ]
    end

    publish(:direct_exchange, "Test Message", {}, {routing_key: "test_binding"})
    publish(:direct_exchange, "Spec Message", {}, {routing_key: "spec_binding"})
    """

    Then I expect to find 2 messages on :my_queue with:
      | body         |
      | Test Message |
      | Spec Message |

  Scenario: Binding an exchange to an exchange
    RabbitMQ's AMQP 0.9 extenstions support binding exchanges to exchanges

    When I execute the following code:
    """ruby
    MessageDriver::Broker.define do |b|
      b.destination :fanout, "amq.fanout", type: :exchange, bindings: [
        {source: "amq.direct", args: {routing_key: "test_binding"}},
        {source: "amq.direct", args: {routing_key: "spec_binding"}}
      ]
      b.destination :my_queue, "my_queue", exclusive: true, bindings: [{source: "amq.fanout"}]
    end

    publish(:direct_exchange, "Test Message", {}, {routing_key: "test_binding"})
    publish(:direct_exchange, "Spec Message", {}, {routing_key: "spec_binding"})
    """

    Then I expect to find 2 messages on :my_queue with:
      | body         |
      | Test Message |
      | Spec Message |
