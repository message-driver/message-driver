@bunny
Feature: DLQ-ing messages with nacks and consumers

  RabbitMQ supports sending messages to a DLQ if configured correctly.
  See http://www.rabbitmq.com/dlx.html for details.

  Background:
    Given the following broker configuration
    """ruby
    MessageDriver::Broker.define do |b|
      # declare a dead letter exchange
      b.destination :rabbit_dlx, "rabbit.dead.letter.exchange", type: :exchange, declare: { type: :fanout }

      # declare a dead letter queue and bind it to the exchange
      b.destination :rabbit_dlq, "rabbit.dead.letter.queue", bindings: [
        { source: "rabbit.dead.letter.exchange" }
      ]

      # declare a work queue that sends dead letters to our dead letter queue
      b.destination :rabbit_work, "rabbit.work", arguments: { :"x-dead-letter-exchange" => "rabbit.dead.letter.exchange" }
    end
    """
    And I have no messages on :rabbit_work
    And I have no messages on :rabbit_dlq

  Scenario: Nacking a message with requeue false
    Given I send the following message to :rabbit_work
      | body        |
      | Nack Test 1 |

    When I execute the following code
    """ruby
    message = MessageDriver::Client.pop_message(:rabbit_work, client_ack: true)
    message.nack(requeue: false)
    """

    Then I expect to find no messages on :rabbit_work
    And I expect to find the following 1 message on :rabbit_dlq
      | body        |
      | Nack Test 1 |


  Scenario: Nacking a message on a manual_ack consumer
    Given I have a message consumer
    """ruby
    MessageDriver::Broker.consumer(:manual_dql) do |message|
      message.nack(requeue: false)
    end
    """
    And I create a subscription
    """ruby
    MessageDriver::Client.subscribe(:rabbit_work, :manual_dql, ack: :manual)
    """

    When I send the following messages to :rabbit_work
      | body          |
      | Manual Nack 1 |
      | Manual Nack 2 |
    And I let the subscription process

    Then I expect to find no messages on :rabbit_work
    And I expect to find the following 2 messages on :rabbit_dlq
      | body          |
      | Manual Nack 1 |
      | Manual Nack 2 |


  Scenario: Raising a DontRequeueError in an auto_ack consumer
    Given I have a message consumer
    """ruby
    MessageDriver::Broker.consumer(:manual_dql) do |message|
      raise MessageDriver::DontRequeueError
    end
    """
    And I create a subscription
    """ruby
    MessageDriver::Client.subscribe(:rabbit_work, :manual_dql, ack: :auto)
    """

    When I send the following messages to :rabbit_work
      | body        |
      | Auto Nack 1 |
      | Auto Nack 2 |
    And I let the subscription process

    Then I expect to find no messages on :rabbit_work
    And I expect to find the following 2 messages on :rabbit_dlq
      | body        |
      | Auto Nack 1 |
      | Auto Nack 2 |


  Scenario: Raising a DontRequeueError in a transactional consumer
    Given I have a message consumer
    """ruby
    MessageDriver::Broker.consumer(:transactional_dql) do |message|
      publish(:rabbit_work, "I get rolled back")
      raise MessageDriver::DontRequeueError
    end
    """
    And I create a subscription
    """ruby
    MessageDriver::Client.subscribe(:rabbit_work, :transactional_dql, ack: :transactional)
    """

    When I send the following messages to :rabbit_work
      | body                 |
      | Transactional Nack 1 |
      | Transactional Nack 2 |
    And I let the subscription process

    Then I expect to find no messages on :rabbit_work
    And I expect to find the following 2 messages on :rabbit_dlq
      | body                 |
      | Transactional Nack 1 |
      | Transactional Nack 2 |
