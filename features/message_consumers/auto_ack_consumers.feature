@wip
Feature: Message Consumers auto-acknowledgement
  Background:
    Given I am connected to the broker
    And I have a destination :dest_queue with no messages on it
    And I have a destination :source_queue with no messages on it

  Scenario: Consuming Messages with auto acks (the default)
