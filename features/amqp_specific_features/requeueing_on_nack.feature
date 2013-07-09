@bunny
Feature: Controlling requeue on message nack
  You can control whether or not a message is requeued when you nack the message.
  Exact behavior when requeue is false is specific to your broker's setup.

  Background:
    Given I am connected to the broker
    And I have a destination :source_queue
    And I have the following messages on :source_queue
      | body         |
      | Test Message |

  Scenario: Requeue by default
    When I execute the following code
    """ruby
    message = MessageDriver::Client.pop_message(:source_queue, client_ack: true)
    message.nack
    """

    Then I expect to find the following message on :source_queue
      | body         |
      | Test Message |


  Scenario: Requeue is true
    When I execute the following code
    """ruby
    message = MessageDriver::Client.pop_message(:source_queue, client_ack: true)
    message.nack(requeue: true)
    """

    Then I expect to find the following message on :source_queue
      | body         |
      | Test Message |


  Scenario: Requeue is false
    When I execute the following code
    """ruby
    message = MessageDriver::Client.pop_message(:source_queue, client_ack: true)
    message.nack(requeue: false)
    """

    Then I expect to find no messages on :source_queue
