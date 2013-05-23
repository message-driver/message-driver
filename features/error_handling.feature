Feature: Error Handling

  Background:
    Given I am connected to the broker

  @bunny
  Scenario: Queue isn't found on the broker
    When I execute the following code:
    """ruby
    MessageDriver::Broker.dynamic_destination("missing_queue", passive: true)
    """

    Then I expect it to raise a MessageDriver::QueueNotFound error

  @no_travis
  @bunny
  Scenario: The broker goes down
    Given the following broker configuration:
    """ruby
    MessageDriver::Broker.define do |b|
      b.destination :my_queue, "broker_down_queue", arguments: {:'x-expires' => 10000 }
    end
    """

    When I execute the following code:
    """ruby
    publish(:my_queue, "Test Message 1")
    """
    And the broker goes down
    And I execute the following code:
    """ruby
    publish(:my_queue, "Test Message 2")
    """
    Then I expect it to raise a MessageDriver::ConnectionError error

    When the broker comes up
    And I execute the following code:
    """ruby
    publish(:my_queue, "Test Message 3")
    """

    Then I expect to have no errors
    And I expect to find 2 messages on :my_queue with:
      | body           |
      | Test Message 1 |
      | Test Message 3 |

