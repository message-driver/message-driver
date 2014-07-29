@bunny
@in_memory
Feature: Middleware Basics

  Middlewares can be used to transform messages that are about to be published
  or that are about to be consumed. This allows for handling of things like
  serializing and deserializing the message body in a way that is transparent to
  your application code.

  Middlewares are applied in a stack to destinations, much like Rack middleware.
  As a message that is about to be consumed, it starts by coming in the top of
  the middleware stack and works it's way down before it is returned by
  `pop_message` or passed to a consumer.

  For messages that are being published, they start at the bottom of the stack
  and work their way up until they are finally passed to the underlying driver
  and sent to the message broker.

  Background:
    Given I am connected to the broker
    And I have a destination :middleware_queue with no messages on it
    And I have a middleware class
    """ruby
    class ExampleMiddleware < MessageDriver::Middleware::Base
      def on_publish(body, headers, properties)
        [body+':about_to_publish', headers, properties]
      end

      def on_consume(body, headers, properties)
        ['about_to_be_consumed:'+body, headers, properties]
      end
    end
    """

  Scenario: The middleware stack of a destination is initially empty
    When I execute the following code
    """ruby
    destination = MessageDriver::Client.find_destination(:middleware_queue)
    expect(destination.middleware).to be_empty
    """
    Then I expect to have no errors


  Scenario: Adding a piece of middleware to a destination
    When I execute the following code
    """ruby
    destination = MessageDriver::Client.find_destination(:middleware_queue)
    destination.middleware.append ExampleMiddleware
    """

    Then I expect the following check to pass
    """ruby
    destination = MessageDriver::Client.find_destination(:middleware_queue)
    expect(destination.middleware).to include(an_instance_of(ExampleMiddleware))
    """


  Scenario: Middleware is applied to messages as they are published
    When I append middleware "ExampleMiddleware" to :middleware_queue
    And I send the following messages to :middleware_queue
      | body           |
      | Test Message 1 |
      | Test Message 2 |

    Then I expect to find the following 2 messages on :middleware_queue
      | raw_body                        |
      | Test Message 1:about_to_publish |
      | Test Message 2:about_to_publish |


  Scenario: Middleware is applied to messages as they are consumed
    Given I have a destination :dest_queue with no messages on it

    When I send the following messages to :middleware_queue
      | body           |
      | Test Message 1 |
      | Test Message 2 |
    And I append middleware "ExampleMiddleware" to :middleware_queue
    And I create a subscription
    """ruby
    MessageDriver::Client.subscribe_with(:middleware_queue) do |message|
      MessageDriver::Client.publish(:dest_queue, message.body)
    end
    """
    And I let the subscription process

    Then I expect to find no messages on :middleware_queue
    And I expect to find the following 2 messages on :dest_queue
      | raw_body                            |
      | about_to_be_consumed:Test Message 1 |
      | about_to_be_consumed:Test Message 2 |
