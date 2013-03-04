@sending_a_message
Feature: Sending A Message

  Scenario:
    When I send a message to "my_queue"
    Then it ends up at the destination "my_queue"
