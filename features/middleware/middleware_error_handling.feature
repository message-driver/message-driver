@bunny
Feature: Middleware Error Handling

  If a middleware raises an error, we need to ensure it is handled properly.

  Background:
    Given I am connected to the broker
    And I have a destination :middleware_queue with no messages on it
    And I have a middleware class
    """ruby
    class ErrorMiddleware < MessageDriver::Middleware::Base
      # def on_publish(body, headers, properties)
      #   [body, headers, properties]
      # end

      def on_consume(body, headers, properties)
        if body.start_with? 'error'
          raise "error trying to consume! #{body}"
        else
          [body, headers, properties]
        end
      end
    end
    """
    And I append middleware "ErrorMiddleware" to :middleware_queue
    And I have a destination :dest_queue with no messages on it

  @in_memory
  Scenario: Publishing a message
    Given I have a middleware class
    """ruby
    class PublishErrorMiddleware < MessageDriver::Middleware::Base
      def on_publish(body, headers, properties)
        raise 'error trying to publish!'
      end

      def on_consume(body, headers, properties)
        [body, headers, properties]
      end
    end
    """
    And I append middleware "PublishErrorMiddleware" to :middleware_queue

    When I execute the following code
    """ruby
    MessageDriver::Client.publish(:middleware_queue, 'middleware error test')
    """
    Then I expect it to raise "error trying to publish!"
    And I expect to find no message on :middleware_queue


  Scenario: Consuming a message with an auto-ack consumer
    Given I create a subscription
    """ruby
    MessageDriver::Client.subscribe_with(:middleware_queue) do |message|
      MessageDriver::Client.publish(:dest_queue, message.body)
    end
    """

    When I send the following message to :middleware_queue
      | body           |
      | Test Message 1 |
      | error message  |
      | Test Message 2 |
    And I let the subscription process

    Then I expect to find the following 2 messages on :dest_queue
      | body           |
      | Test Message 1 |
      | Test Message 2 |
    And I expect to find the following message on :middleware_queue
      | body          |
      | error message |

  Scenario: Consuming with a manual ack consumer
    Given I create a subscription
    """ruby
    MessageDriver::Client.subscribe_with(:middleware_queue, ack: :manual) do |message|
      MessageDriver::Client.publish(:dest_queue, message.body)
      message.ack
    end
    """

    When I send the following message to :middleware_queue
      | body           |
      | Test Message 1 |
      | error message  |
      | Test Message 2 |
    And I let the subscription process

    Then I expect to find the following 2 messages on :dest_queue
      | body           |
      | Test Message 1 |
      | Test Message 2 |
    And I expect to find the following message on :middleware_queue
      | body          |
      | error message |

  Scenario: Consuming with a transactional ack consumer
    Given I create a subscription
    """ruby
    MessageDriver::Client.subscribe_with(:middleware_queue, ack: :transactional) do |message|
      MessageDriver::Client.publish(:dest_queue, message.body)
    end
    """

    When I send the following message to :middleware_queue
      | body           |
      | Test Message 1 |
      | error message  |
      | Test Message 2 |
    And I let the subscription process

    Then I expect to find the following 2 messages on :dest_queue
      | body           |
      | Test Message 1 |
      | Test Message 2 |
    And I expect to find the following message on :middleware_queue
      | body          |
      | error message |
