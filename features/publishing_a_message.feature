@all_adapters
Feature: Publishing A Message
  Background:
    Given the following broker configuration:
    """ruby
    MessageDriver::Broker.define do |b|
      b.destination :my_queue, "my_queue"
    end
    """

  Scenario: Running within a with_message_transaction block
    When I execute the following code:
    """ruby
    publish(:my_queue, "Test Message")
    """

    Then I expect to find 1 message on :my_queue with:
      | body         |
      | Test Message |
