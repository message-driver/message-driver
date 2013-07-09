@bunny
Feature: Client Acks
  Support for doing client acks on messages

  Background:
    Given I am connected to the broker
    And I have a destination :source_queue
    And I have the following messages on :source_queue
      | body         |
      | Test Message |


  Scenario: Calling ack on the message to acknowledge it
    When I execute the following code
    """ruby
    message = MessageDriver::Client.pop_message(:source_queue, client_ack: true)
    message.ack
    """

    Then I expect to find no messages on :source_queue


  Scenario: Calling nack on the message to put it back on the queue
    When I execute the following code
    """ruby
    message = MessageDriver::Client.pop_message(:source_queue, client_ack: true)
    message.nack
    """

    Then I expect to find the following message on :source_queue
      | body         |
      | Test Message |


  Scenario: Acking in a transaction that commits
    When I execute the following code
    """ruby
    MessageDriver::Client.with_message_transaction do
      message = MessageDriver::Client.pop_message(:source_queue, client_ack: true)
      message.ack
    end
    """

    Then I expect to find no messages on :source_queue


  Scenario: Nacking in a transaction that commits
    When I execute the following code
    """ruby
    MessageDriver::Client.with_message_transaction do
      message = MessageDriver::Client.pop_message(:source_queue, client_ack: true)
      message.nack
    end
    """

    Then I expect to find the following message on :source_queue
      | body         |
      | Test Message |


  Scenario: Acking in a transaction that rolls back
    When I execute the following code
    """ruby
    MessageDriver::Client.with_message_transaction do
      message = MessageDriver::Client.pop_message(:source_queue, client_ack: true)
      message.ack
      raise "rollback the transaction"
    end
    """
    And I reset the context

    Then I expect it to raise "rollback the transaction"
    And I expect to find the following message on :source_queue
      | body         |
      | Test Message |


  Scenario: Nacking in a transaction that rolls back
    When I execute the following code
    """ruby
    MessageDriver::Client.with_message_transaction do
      message = MessageDriver::Client.pop_message(:source_queue, client_ack: true)
      message.nack
      raise "rollback the transaction"
    end
    """
    And I reset the context

    Then I expect it to raise "rollback the transaction"
    And I expect to find the following message on :source_queue
      | body         |
      | Test Message |
