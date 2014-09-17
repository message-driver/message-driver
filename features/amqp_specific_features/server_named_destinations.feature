@bunny
@read_queues_directly
Feature: Server-Named Destinations
  AMQP brokers allow you to create queues that are named by the server. Here's
  how you do it with message_driver.

  Scenario: Creating a server-named queue
    I expect my destination to have the queue name given to it by the server

    Given I am connected to the broker

    When I execute the following code
    """ruby
    destination = MessageDriver::Client.dynamic_destination("", exclusive: true)
    expect(destination.name).to_not be_empty
    """

    Then I expect to have no errors

  Scenario: sending and receiving messages through a server-named queue
    Given the following broker configuration
    """ruby
    MessageDriver::Broker.define do |b|
      b.destination :my_queue, "", exclusive: true
    end
    """

    When I execute the following code
    """ruby
    publish(:my_queue, "server-named queue message")
    """

    Then I expect to find the following message on :my_queue
      | body                       |
      | server-named queue message |
