@sending_a_message
Feature: Sending A Message
  Background:
    Given there is a broker
    And there is a destination "my_queue"

  Scenario:
    When I send a message to "my_queue"
    Then it ends up at the destination "my_queue"
