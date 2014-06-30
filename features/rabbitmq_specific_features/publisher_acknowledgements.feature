@bunny
Feature: Publisher Acknowledgements

  RabbitMQ supports confirmation of published messages
  See http://www.rabbitmq.com/confirms.html for details.

  Verifying the publish of a single message and of a group of messages is
  supported as described below.

  Background:
    Given I am connected to the broker
    And I have a destination :publish_ack with no messages on it

  Scenario: Publishing a single message with confirmations turned on
    When I execute the following code
    """"ruby
    publish(:publish_ack, "Test Message", {}, confirm: true)
    """

    Then I expect all the publishes to have been acknowledged
    And I expect to find the following message on :publish_ack
      | body         |
      | Test Message |


  Scenario: Publishing a single message where confirmations are turned on by the destination
    When I execute the following code
    """"ruby
    my_new_destination = MessageDriver::Client.dynamic_destination(:publish_ack, {}, {confirm: true})
    my_new_destination.publish("Test Message")
    """

    Then I expect all the publishes to have been acknowledged
    And I expect to find the following message on :publish_ack
      | body         |
      | Test Message |


  Scenario: Publishing a batch of messages with confirmations turned on
    When I execute the following code
    """"ruby
    with_message_transaction(type: :confirm_and_wait) do
      50.times do |i|
        publish(:publish_ack, "Test Message #{i}")
      end
    end
    """

    Then I expect all the publishes to have been acknowledged
    And I expect that we are not in transaction mode
    And I expect to find 50 messages on :publish_ack
