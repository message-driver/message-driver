@bunny
@in_memory
Feature: You can get metadata about your destinations
  Background:
    Given The following broker configuration:
    """ruby
    MessageDriver::Broker.define do |b|
      b.destination :my_queue, "my_queue", exclusive: true
    end
    """

  Scenario: Checking the message count when the queue is empty
    When I execute the following code:
    """ruby
    destination = MessageDriver::Broker.find_destination(:my_queue)
    expect(destination.message_count).to eq(0)
    """

    Then I expect to have no errors
    And I expect to find no messages on :my_queue

  @no_travis
  Scenario: Checking the message count when the queue has messages
    When I execute the following code:
    """ruby
    publish(:my_queue, "test message 1")
    publish(:my_queue, "test message 2")
    destination = MessageDriver::Broker.find_destination(:my_queue)
    expect(destination.message_count).to eq(2)
    """

    Then I expect to have no errors
    And I expect to find 2 messages on :my_queue
