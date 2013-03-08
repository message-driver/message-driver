@bunny
Feature: Publishing a Message within a Transaction
  Background:
    Given The following broker configuration:
    """ruby
    MessageDriver::Broker.define do |b|
      b.destination :my_queue, "my_queue", exclusive: true
    end
    """

  Scenario: The block completes successfully
    When I execute the following code:
    """ruby
    with_message_transaction do
      publish(:my_queue, "Transacted Message 1")
      publish(:my_queue, "Transacted Message 2")
    end
    """

    Then I expect to find 2 messages on :my_queue with:
      | body                 |
      | Transacted Message 1 |
      | Transacted Message 2 |

  Scenario: An error is raised inside the block
    When I execute the following code:
    """ruby
    with_message_transaction do
      publish(:my_queue, "Transacted Message 1")
      raise "an error that causes a rollback"
      publish(:my_queue, "Transacted Message 2")
    end
    """

    Then I expect it to raise "an error that causes a rollback"
    And I expect to find no messages on :my_queue
