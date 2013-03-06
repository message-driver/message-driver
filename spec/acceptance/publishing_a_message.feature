@publishing_a_message
Feature: Publishing A Message
  Background:
    Given I have a destination "my_queue"

  Scenario:
    When I publish a message to "my_queue"
    Then it ends up at the destination "my_queue"
