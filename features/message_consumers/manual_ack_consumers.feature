@bunny
Feature: Manual Message Acknowledgement
  This mode requires the consumer to call ack on the message in order to acknowledge it

  Background:
    Given I am connected to the broker
    And I have a destination :source_queue with no messages on it

  Scenario: Consuming Messages
    Given I have a message consumer
    """ruby
    MessageDriver::Client.consumer(:my_consumer) do |message|
      message.ack
    end
    """
    And I create a subscription
    """ruby
    MessageDriver::Client.subscribe(:source_queue, :my_consumer, ack: :manual)
    """

    When I send the following messages to :source_queue
      | body           |
      | Test Message 1 |
      | Test Message 2 |
    And I let the subscription process

    Then I expect to find no messages on :source_queue

  Scenario: When a message is nack'ed
    Given I have a message consumer
    """ruby
    MessageDriver::Client.consumer(:my_consumer) do |message|
      message.nack(requeue: true)
    end
    """
    And I create a subscription
    """ruby
    MessageDriver::Client.subscribe(:source_queue, :my_consumer, ack: :manual)
    """

    When I send the following messages to :source_queue
      | body           |
      | Test Message 1 |
      | Test Message 2 |
    And I let the subscription process

    Then I expect to find the following 2 messages on :source_queue
      | body           |
      | Test Message 1 |
      | Test Message 2 |

  Scenario: When an occurs before the message is ack'ed
    Given I have a message consumer
    """ruby
    MessageDriver::Client.consumer(:my_consumer) do |message|
      raise "oh nos!"
      message.ack
    end
    """
    And I create a subscription
    """ruby
    MessageDriver::Client.subscribe(:source_queue, :my_consumer, ack: :manual)
    """

    When I send the following messages to :source_queue
      | body           |
      | Test Message 1 |
      | Test Message 2 |
    And I let the subscription process

    Then I expect to find the following 2 messages on :source_queue
      | body           |
      | Test Message 1 |
      | Test Message 2 |

  Scenario: When an error occurs after the message is ack'ed
    Given I have a message consumer
    """ruby
    MessageDriver::Client.consumer(:my_consumer) do |message|
      message.ack
      raise "oh nos!"
    end
    """
    And I create a subscription
    """ruby
    MessageDriver::Client.subscribe(:source_queue, :my_consumer, ack: :manual)
    """

    When I send the following messages to :source_queue
      | body           |
      | Test Message 1 |
      | Test Message 2 |
    And I let the subscription process

    Then I expect to find no messages on :source_queue
