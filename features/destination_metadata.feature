@bunny
@in_memory
Feature: Destination Metadata
  Background:
    Given I am connected to the broker
    And I have a destination :my_queue with no messages on it

  Scenario: Checking the message count when the queue is empty
    When I execute the following code
    """ruby
    destination = MessageDriver::Client.find_destination(:my_queue)
    expect(destination.message_count).to eq(0)
    """

    Then I expect to have no errors
    And I expect to find no messages on :my_queue

  Scenario: Checking the message count when the queue has messages
    When I send the following messages to :my_queue
      | body           |
      | Test Message 1 |
      | Test Message 2 |
    And I allow for processing
    And I execute the following code
    """ruby
    destination = MessageDriver::Client.find_destination(:my_queue)
    expect(destination.message_count).to eq(2)
    """

    Then I expect to have no errors
    And I expect to find 2 messages on :my_queue
