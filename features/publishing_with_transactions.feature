@bunny
Feature: Publishing a Message within a Transaction
  Background:
    Given I am connected to the broker
    And I have a destination :publish_transaction with no messages on it

  Scenario: The block completes successfully
    When I execute the following code
    """ruby
    with_message_transaction do
      publish(:publish_transaction, "Transacted Message 1")
      publish(:publish_transaction, "Transacted Message 2")
    end
    """

    Then I expect to find the following 2 messages on :publish_transaction
      | body                 |
      | Transacted Message 1 |
      | Transacted Message 2 |

  Scenario: An error is raised inside the block
    When I execute the following code
    """ruby
    with_message_transaction do
      publish(:publish_transaction, "Transacted Message 1")
      raise "an error that causes a rollback"
      publish(:publish_transaction, "Transacted Message 2")
    end
    """

    Then I expect it to raise "an error that causes a rollback"
    And I expect to find no messages on :publish_transaction
