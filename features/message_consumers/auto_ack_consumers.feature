@bunny
Feature: Automatic Message Acknowledgement
  This mode will ack the message if the consumer completes successfully.
  It will nack the message if the consumer raises an error.

  Background:
    Given I am connected to the broker
    And I have a destination :dest_queue with no messages on it
    And I have a destination :source_queue with no messages on it

  Scenario: Consuming Messages
    Given I have a message consumer
    """ruby
    MessageDriver::Client.consumer(:my_consumer) do |message|
      MessageDriver::Client.publish(:dest_queue, message.body)
    end
    """
    And I create a subscription
    """ruby
    MessageDriver::Client.subscribe(:source_queue, :my_consumer, ack: :auto)
    """

    When I send the following messages to :source_queue
      | body       |
      | Auto Ack 1 |
      | Auto Ack 2 |
    And I let the subscription process

    Then I expect to find no messages on :source_queue
    And I expect to find the following 2 messages on :dest_queue
      | body       |
      | Auto Ack 1 |
      | Auto Ack 2 |


  Scenario: An error occurs during processing
    Given I have a message consumer
    """ruby
    MessageDriver::Client.consumer(:my_consumer) do |message|
      raise "oh nos!"
    end
    """
    And I create a subscription
    """ruby
    MessageDriver::Client.subscribe(:source_queue, :my_consumer, ack: :auto)
    """

    When I send the following messages to :source_queue
      | body             |
      | Auto Ack Error 1 |
      | Auto Ack Error 2 |
    And I let the subscription process

    Then I expect to find no messages on :dest_queue
    And I expect to find the following 2 messages on :source_queue
      | body             |
      | Auto Ack Error 1 |
      | Auto Ack Error 2 |

  Scenario: A DontRequeue error occurs during processing
    Given I have a message consumer
    """ruby
    MessageDriver::Client.consumer(:my_consumer) do |message|
      raise MessageDriver::DontRequeueError, "don't requeue me"
    end
    """
    And I create a subscription
    """ruby
    MessageDriver::Client.subscribe(:source_queue, :my_consumer, ack: :auto)
    """

    When I send the following messages to :source_queue
      | body             |
      | Auto Ack Error 1 |
      | Auto Ack Error 2 |
    And I let the subscription process

    Then I expect to find no messages on :dest_queue
    And I expect to find no messages on :source_queue
