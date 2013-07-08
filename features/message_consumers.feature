@in_memory
Feature: Message Consumers
  Background:
    Given I am connected to the broker
    Given I have a destination :dest_queue
    And I have a destination :source_queue

    And I have a message consumer
    """ruby
    MessageDriver::Broker.consumer(:my_consumer) do |message|
      MessageDriver::Client.publish(:dest_queue, message.body)
    end
    """

  Scenario: Consuming Messages
    Given I subscribe to :source_queue with :my_consumer

    When I send the following messages to :source_queue
      | body           |
      | Test Message 1 |
      | Test Message 2 |

    Then I expect to find no messages on :source_queue
    And I expect to find the following 2 messages on :dest_queue
      | body           |
      | Test Message 1 |
      | Test Message 2 |

  Scenario: Ending a subscription
    When I execute the following code
    """ruby
    @subscription = MessageDriver::Client.subscribe(:source_queue, :my_consumer)
    """

    When I send the following messages to :source_queue
      | body           |
      | Test Message 1 |
      | Test Message 2 |
    And I execute the following code
    """ruby
    @subscription.unsubscribe
    """
    When I send the following messages to :source_queue
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
