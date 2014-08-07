@bunny
@in_memory
Feature: Middleware Parameters

  You can provide parameters to your middleware by passing them as additional
  paremeters to the append and prepend calls.

  Background:
    Given I am connected to the broker
    And I have a destination :middleware_queue with no messages on it
    And I have a middleware class
    """ruby
    class ParameterizedMiddleware < MessageDriver::Middleware::Base

      attr_reader :prefix, :seperator

      def initialize(destination, prefix, seperator)
        super(destination)
        @prefix = prefix
        @seperator = seperator
      end

      def on_publish(body, headers, properties)
        ["#{prefix}#{seperator}#{body}", headers, properties]
      end
    end
    """

  Scenario: Adding a parameterized middleware to the stack
    When I execute the following code
    """ruby
    destination = MessageDriver::Client.find_destination(:middleware_queue)
    destination.middleware.append ParameterizedMiddleware, 'pub_pre', ':'
    """
    And I send the following messages to :middleware_queue
      | body           |
      | Test Message 1 |
      | Test Message 2 |

    Then I expect to find the following 2 messages on :middleware_queue
      | raw_body               |
      | pub_pre:Test Message 1 |
      | pub_pre:Test Message 2 |
