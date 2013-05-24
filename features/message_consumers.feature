@in_memory
Feature: Message Consumers
  Background:
    Given I am connected to the broker

  Scenario: Consuming Messages
    Given I have a destination :dest_queue
    And I have a destination :source_queue

    And I have a message processor
    """ruby
    MessageDriver::Broker.consumer(:my_consumer) do |message|
      MessageDriver::Broker.publish(:dest_queue, message.body)
    end
    """
    And I subscribe to :source_queue with :my_consumer

    When I send the following messages to :source_queue
      | body           |
      | Test Message 1 |
      | Test Message 2 |

    Then I expect to find no messages on :source_queue
    And I expect to find the following 2 messages on :dest_queue
      | body           |
      | Test Message 1 |
      | Test Message 2 |
