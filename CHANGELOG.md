# Changelog

## 0.2.0

no changes yet

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
