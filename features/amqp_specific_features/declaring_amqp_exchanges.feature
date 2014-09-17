@bunny
@read_queues_directly
Feature: Declaring AMQP exchanges
  If you want to create an exchange that doesn't exist on the broker, you can do so by adding
  the "declare" option to your destination.

  Background:
    Given I am connected to the broker

  Scenario: Declaring a direct exchange
    When I execute the following code
    """ruby
    MessageDriver::Broker.define do |b|
      b.destination :my_exchange, "my_exchange", type: :exchange, declare: {type: :direct, auto_delete: true}
      b.destination :exchange_bound_queue, "", exclusive: true, bindings: [{source: "my_exchange", routing_key: "exchange_bound_queue"}]
    end

    publish(:my_exchange, "Test My New Exchange", routing_key: "exchange_bound_queue")
    """

    Then I expect to find the following message on :exchange_bound_queue
      | body                 |
      | Test My New Exchange |
