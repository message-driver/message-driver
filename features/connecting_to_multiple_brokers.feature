Feature: Connecting to Multiple Brokers

  Background:
    Given I am connected to a broker named :my_broker

  @all_adapters
  Scenario: Declaring Destinations and Publishing on a secondary broker
    Given I configure my broker as follows
    """ruby
    MessageDriver::Broker.define(:my_broker) do |b|
      b.destination(:multi_broker_destination, "multi.broker.queue")
    end
    """
    And I have no messages on :multi_broker_destination

    When I execute the following code
    """ruby
    MessageDriver::Client[:my_broker].publish(:multi_broker_destination, "Test Message")
    """

    Then I expect to find the following message on :multi_broker_destination
      | body         |
      | Test Message |

  @bunny
  @in_memory
  Scenario: Declaring Consumers and Subscriptions on a secondary broker
    Given I have a destination :dest_queue with no messages on it
    And I have a destination :source_queue with no messages on it
    And I have a message consumer
    """ruby
    MessageDriver::Client[:my_broker].consumer(:my_consumer) do |message|
      MessageDriver::Client[:my_broker].publish(:dest_queue, message.body)
    end
    """
    And I create a subscription
    """ruby
    MessageDriver::Client[:my_broker].subscribe(:source_queue, :my_consumer)
    """

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
