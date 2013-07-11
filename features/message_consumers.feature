@in_memory
@bunny
Feature: Message Consumers
  Background:
    Given I am connected to the broker
    And I have a destination :dest_queue with no messages on it
    And I have a destination :source_queue with no messages on it
    And I have a message consumer
    """ruby
    MessageDriver::Broker.consumer(:my_consumer) do |message|
      MessageDriver::Client.publish(:dest_queue, message.body)
    end
    """
    And I create a subscription
    """ruby
    MessageDriver::Client.subscribe(:source_queue, :my_consumer)
    """


  Scenario: Consuming Messages
    When I send the following messages to :source_queue
      | body           |
      | Test Message 1 |
      | Test Message 2 |
    And I let the subscription process

    Then I expect to find no messages on :source_queue
    And I expect to find the following 2 messages on :dest_queue
      | body           |
      | Test Message 1 |
      | Test Message 2 |


  Scenario: Ending a subscription
    When I send the following messages to :source_queue
      | body           |
      | Test Message 1 |
      | Test Message 2 |
    And I allow for processing
    And I cancel the subscription
    And I send the following messages to :source_queue
      | body           |
      | Test Message 3 |
      | Test Message 4 |

    Then I expect to find the following 2 messages on :dest_queue
      | body           |
      | Test Message 1 |
      | Test Message 2 |

    And I expect to find the following 2 messages on :source_queue
      | body           |
      | Test Message 3 |
      | Test Message 4 |
