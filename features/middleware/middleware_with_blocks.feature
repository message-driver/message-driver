@bunny
@in_memory
Feature: Middleware with blocks

  You can also create middleware by passing a hash with blocks as the input to
  append or prepend

  Background:
    Given I am connected to the broker
    And I have a destination :middleware_queue with no messages on it

  Scenario: providing an on_publish block
    When I execute the following code
    """ruby
      destination = MessageDriver::Client.find_destination(:middleware_queue)
      destination.middleware.append on_publish: ->(body, headers, properties) { [body+' published with a block!', headers, properties] }
    """

    And I send the following messages to :middleware_queue
      | body           |
      | Test Message 1 |
      | Test Message 2 |

    Then I expect to find the following 2 messages on :middleware_queue
      | raw_body               |
      | Test Message 1 published with a block! |
      | Test Message 2 published with a block! |


  Scenario: providing an on_consume block
    Given I have a destination :dest_queue with no messages on it

    When I execute the following code
    """ruby
      destination = MessageDriver::Client.find_destination(:middleware_queue)
      destination.middleware.append on_consume: ->(body, headers, properties) { [body+' consumed with a block!', headers, properties] }
    """

    And I send the following messages to :middleware_queue
      | body           |
      | Test Message 1 |
      | Test Message 2 |

    And I create a subscription
    """ruby
    MessageDriver::Client.subscribe_with(:middleware_queue) do |message|
      MessageDriver::Client.publish(:dest_queue, message.body)
    end
    """
    And I let the subscription process

    Then I expect to find no messages on :middleware_queue
    And I expect to find the following 2 messages on :dest_queue
      | raw_body                              |
      | Test Message 1 consumed with a block! |
      | Test Message 2 consumed with a block! |

  Scenario: providing an on_consume block and an on_publish block
    Given I have a destination :dest_queue with no messages on it

    When I execute the following code
    """ruby
      destination = MessageDriver::Client.find_destination(:middleware_queue)
      destination.middleware.append(on_consume: ->(body, headers, properties) { [body + ' consumed', headers, properties] },
                                    on_publish: ->(body, headers, properties) { ['published ' + body, headers, properties] })
    """

    And I send the following messages to :middleware_queue
      | body           |
      | Test Message 1 |
      | Test Message 2 |

    And I create a subscription
    """ruby
    MessageDriver::Client.subscribe_with(:middleware_queue) do |message|
      MessageDriver::Client.publish(:dest_queue, message.body)
    end
    """
    And I let the subscription process

    Then I expect to find no messages on :middleware_queue
    And I expect to find the following 2 messages on :dest_queue
      | raw_body                              |
      | published Test Message 1 consumed |
      | published Test Message 2 consumed |
