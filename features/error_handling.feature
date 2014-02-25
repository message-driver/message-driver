Feature: Error Handling

  @bunny
  Scenario: Queue isn't found on the broker
    Given I am connected to the broker
    When I execute the following code
    """ruby
    MessageDriver::Client.dynamic_destination("missing_queue", passive: true)
    """

    Then I expect it to raise a MessageDriver::QueueNotFound error

  @no_ci
  @bunny
  @slow
  Scenario: The broker goes down
    Given the following broker configuration
    """ruby
    MessageDriver::Broker.define do |b|
      b.destination :my_queue, "broker_down_queue", durable: true, arguments: {:'x-expires' => 1000*60*10 } #expires in 10 minutes
    end
    """
    And I have no messages on :my_queue

    When I execute the following code
    """ruby
    publish(:my_queue, "Test Message 1")
    """
    And the broker goes down
    And I execute the following code
    """ruby
    publish(:my_queue, "Test Message 2")
    """
    Then I expect it to raise a MessageDriver::ConnectionError error

    When the broker comes up
    And I execute the following code
    """ruby
    publish(:my_queue, "Test Message 3")
    """

    Then I expect to have no errors
    And I expect to find the following 2 messages on :my_queue
      | body           |
      | Test Message 1 |
      | Test Message 3 |

