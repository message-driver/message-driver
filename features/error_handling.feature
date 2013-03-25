Feature: Error Handling

  @wip
  @bunny
  Scenario: Queue isn't found on the broker
    When I execute the following code:
    """ruby
    MessageDriver::Broker.dynamic_destination("missing_queue", passive: true)
    """

    Then I expect it to raise a MessageDriver::QueueNotFound error
