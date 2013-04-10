@bunny
Feature: Declaring AMQP exchanges
  If you want to create an exchange that doesn't exist on the broker, you can do so by adding
  the "declare" option to your destination.

  Background:
    Given I am connected to the broker

  Scenario: Declaring a direct exchange
    When I execute the following code:
    """ruby
    MessageDriver::Broker.define do |b|
      b.destination :my_exchange, "my_exchange", type: :exchange, declare: {type: :direct, auto_delete: true}
      b.destination :my_queue, "", exclusive: true, bindings: [{source: "my_exchange", routing_key: "my_queue"}]
    end

    publish(:my_exchange, "Test My New Exchange", routing_key: "my_queue")
    """

    Then I expect to find 1 message on :my_queue with:
      | body                 |
      | Test My New Exchange |
