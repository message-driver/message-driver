@all_adapters
Feature: Publishing A Message
  Background:
    Given I am connected to the broker
    And I have a destination :publish_test with no messages on it

  Scenario: Publishing a message
    When I execute the following code
    """ruby
    publish(:publish_test, "Test Message")
    """

    Then I expect to find the following message on :publish_test
      | body         |
      | Test Message |
