@all_adapters
Feature: Dynamic Destinations
  Sometime you want to connect to a queue that has some of it's characteristics
  determined at runtime. Dynamic destinations allow you to do with without
  leaking tons of destination definitions.

  Background:
    Given I am connected to the broker

  Scenario: Sending to a dynamic destination
    When I execute the following code
    """ruby
    my_new_destination = MessageDriver::Broker.dynamic_destination("temp_queue")
    my_new_destination.publish("Test Message")
    """

    Then I expect to find 1 message on the dynamic destination "temp_queue" with
      | body         |
      | Test Message |

  Scenario: Poping messages off a dynamic destination
    Given I have a dynamic destination "temp_queue" with the following messages on it
      | body           |
      | Test Message 1 |
      | Test Message 2 |

    When I execute the following code
    """ruby
    my_new_destination = MessageDriver::Broker.dynamic_destination("temp_queue")

    msg1 = my_new_destination.pop_message
    expect(msg1.body).to eq("Test Message 1")

    msg2 = my_new_destination.pop_message
    expect(msg2.body).to eq("Test Message 2")

    msg3 = my_new_destination.pop_message
    expect(msg3).to be_nil
    """

    Then I expect to have no errors
