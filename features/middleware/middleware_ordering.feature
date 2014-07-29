@bunny
@in_memory
Feature: Middleware Ordering

  Middleware are applied based on the order they appear in the stack. For
  publish operations, middlewares are applied bottom of the stack to the top.
  For consume operations, middleware are applied from the top of the stack to
  the bottom.

  Scenario: Apply two middlewares to a destination
    Given I am connected to the broker
    And I have a destination :middleware_queue with no messages on it
    And I have a middleware class
    """ruby
    class MiddlewareOne < MessageDriver::Middleware::Base
      def on_publish(body, headers, properties)
        [body+':publish1', headers, properties]
      end

      def on_consume(body, headers, properties)
        ['consume1:'+body, headers, properties]
      end
    end
    """
    And I have a middleware class
    """ruby
    class MiddlewareTwo < MessageDriver::Middleware::Base
      def on_publish(body, headers, properties)
        [body+':publish2', headers, properties]
      end

      def on_consume(body, headers, properties)
        ['consume2:'+body, headers, properties]
      end
    end
    """
    And I append middleware "MiddlewareOne" to :middleware_queue
    And I append middleware "MiddlewareTwo" to :middleware_queue

    And I have a destination :dest_queue with no messages on it
    And I create a subscription
    """ruby
    MessageDriver::Client.subscribe_with(:middleware_queue) do |message|
      MessageDriver::Client.publish(:dest_queue, message.body)
    end
    """

    When I send the following messages to :middleware_queue
      | body           |
      | Test Message 1 |
      | Test Message 2 |
      | Test Message 3 |
    And I let the subscription process

    Then I expect to find no messages on :middleware_queue
    And I expect to find the following 3 messages on :dest_queue
      | body                                               |
      | consume1:consume2:Test Message 1:publish1:publish2 |
      | consume1:consume2:Test Message 2:publish1:publish2 |
      | consume1:consume2:Test Message 3:publish1:publish2 |
