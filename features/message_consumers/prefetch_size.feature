@bunny
@wip
Feature: Message Consumers prefetch size
  You can set the prefetch size for your message consumers 

  Background:
    Given I am connected to the broker
    And I have a destination :dest_queue_1 with no messages on it
    And I have a destination :dest_queue_2 with no messages on it
    And I have a destination :source_queue with no messages on it

  Scenario: Consuming Messages
    Given I have a message consumer
    """ruby
    MessageDriver::Broker.consumer(:my_consumer_1) do |message|
      MessageDriver::Client.publish(:dest_queue_1, message.body)
    end
    """
    And I have a message consumer
    """ruby
    MessageDriver::Broker.consumer(:my_consumer_2) do |message|
      MessageDriver::Client.publish(:dest_queue_2, message.body)
    end
    """
    And I create a subscription
    """ruby
    MessageDriver::Client.subscribe(:source_queue, :my_consumer_1, ack: :auto, prefetch_size: 20)
    MessageDriver::Client.subscribe(:source_queue, :my_consumer_2, ack: :auto, prefetch_size: 1)
    """

    When I send the following messages to :source_queue
      | body       |
      | Auto Ack 1 |
      | Auto Ack 2 |
      | Auto Ack 3 |
      | Auto Ack 4 |
      | Auto Ack 5 |
      | Auto Ack 6 |
      | Auto Ack 7 |
      | Auto Ack 8 |
      | Auto Ack 9 |
      | Auto Ack 10 |
    And I let the subscription process

    Then I expect to find no messages on :source_queue
    And I expect to find no messages on :dest_queue_2
    And I expect to find the following 2 messages on :dest_queue_1
      | body       |
      | Auto Ack 1 |
      | Auto Ack 2 |
      | Auto Ack 3 |
      | Auto Ack 4 |
      | Auto Ack 5 |
      | Auto Ack 6 |
      | Auto Ack 7 |
      | Auto Ack 8 |
      | Auto Ack 9 |
      | Auto Ack 10 |

