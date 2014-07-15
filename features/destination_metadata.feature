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

  Scenario: Check the consumer count when the queue has no consumers
    When I execute the following code
    """ruby
    destination = MessageDriver::Client.find_destination(:my_queue)
    expect(destination.consumer_count).to eq(0)
    """

    Then I expect to have no errors

  Scenario: Check the consumer count when the queue has consumers
    Given I create some subscriptions
    """ruby
    3.times do
      MessageDriver::Client.subscribe_with(:my_queue) do |message|
        puts message.inspect
      end
    end
    """
    When I execute the following code
    """ruby
    destination = MessageDriver::Client.find_destination(:my_queue)
    expect(destination.consumer_count).to eq(3)
    """

    Then I expect to have no errors
