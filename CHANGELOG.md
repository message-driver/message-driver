# Changelog

## 0.2.0 - 2013-11-05

* drop support for bunny 0.9.x
* add support for bunny 1.0.x
* ability to create subscriptions from a block instead of having to
  register a consumer

## 0.2.0.rc2 - 2013-10-30

* Features
    * Prefetch size for bunny consumers
* Bugs
    * better error handling for transaction bunny consumers

## 0.2.0.rc1 - 2013-09-23

* Features
    * Message Consumers, all different flavors
        * Bunny and InMemory adapters
    * Client Acks
        * Bunny adapter
    * Bunny adapter
        * much better connection and channel error handling, including
          reconnecting when broker becomes unreachable
* Adapters
    * begin work on Stomp 1.1/1.2 adapter

## 0.1.0 - 2013-04-05

Initial Release

* Features
    * Publish a message
    * Broker transactions for publishing
    * Pop a message
    * named and dynamic destinations
    * message_count for destinations
* Adapters
    * InMemory
        * #reset_after_test method for clearing out queues
    * Bunny (amqp 0.9)
        * handle connection and channel errors transparently
