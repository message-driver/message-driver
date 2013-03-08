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
      publish(:my_queue, "Transacted Message")
    end
    """

    Then I expect to find 1 message on :my_queue with:
      | body               |
      | Transacted Message |

  @pending
  Scenario: An error is raised inside the block
    When I execute the following code:
    """ruby
    with_message_transaction do
      publish(:my_queue, "Transacted Message")
      raise "an error that causes a rollback"
    end
    """

    Then I expect it to raise "an error that causes a rollback"
    And I expect to find no messages on :my_queue
