@bunny
Feature: Nacking Redelievered Messages from a consumer

  You can configure the consumer to nack a re-delievered message. In this example, we use
  a dead letter exchange to show how things end up working.

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
    And I have a destination :rabbit_track with no messages on it


  Scenario: Raising an error in an auto_ack consumer
    Given I have a message consumer
    """ruby
    MessageDriver::Broker.consumer(:manual_redeliver) do |message|
      publish(:rabbit_track, "#{message.body} Attempt")
      raise "oh nos!"
    end
    """
    And I create a subscription
    """ruby
    MessageDriver::Client.subscribe(:rabbit_work, :manual_redeliver, ack: :auto, retry_redelivered: false)
    """

    When I send the following messages to :rabbit_work
      | body         |
      | Auto Retry 1 |
      | Auto Retry 2 |
    And I let the subscription process

    Then I expect to find no messages on :rabbit_work
    And I expect to find the following 2 messages on :rabbit_dlq
      | body         |
      | Auto Retry 1 |
      | Auto Retry 2 |
    And I expect to find the following 4 messages on :rabbit_track
      | body                 |
      | Auto Retry 1 Attempt |
      | Auto Retry 2 Attempt |
      | Auto Retry 1 Attempt |
      | Auto Retry 2 Attempt |


  Scenario: Raising an error in a transactional consumer
    Given I have a message consumer
    """ruby
    @attempts = 0
    MessageDriver::Broker.consumer(:transactional_redeliver) do |message|
      publish(:rabbit_track, "#{message.body} Attempt")
      @attempts += 1
      raise "oh nos!"
    end
    """
    And I create a subscription
    """ruby
    MessageDriver::Client.subscribe(:rabbit_work, :transactional_redeliver, ack: :transactional, retry_redelivered: false)
    """

    When I send the following messages to :rabbit_work
      | body                      |
      | Transactional Redeliver 1 |
      | Transactional Redeliver 2 |
    And I let the subscription process
    And I restart the subscription
    And I let the subscription process

    Then I expect to find no messages on :rabbit_track
    Then I expect to find no messages on :rabbit_work
    Then I expect the following check to pass
    """ruby
    expect(@attempts).to eq(4)
    """
    Then I expect to find the following 2 messages on :rabbit_dlq
      | body                      |
      | Transactional Redeliver 1 |
      | Transactional Redeliver 2 |
