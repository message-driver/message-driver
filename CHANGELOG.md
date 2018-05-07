# Changelog

## 1.0.0 - 2018-05-07

We decided to go 1.0 just because it was time to be done with the 0.x since we have been using this in production since 2013.

* drop support for rubinius, old jruby and MRI < 2.2
* drop support for bunny < 2.7

## 0.7.2 - 2017-10-06

* Fix some additional edge cases related to #35, where an error could cause a message to be nil

## 0.7.1 - 2017-04-10

* Move middleware processing for consumers inside the message handler so error in middleware are correctly handled - Fixes #35

## 0.7.0 - 2016-12-19

* update test gems
* drop support for ruby 1.9.2
* test against newer versions of bunny
* Restructure internal API for adapter contexts to better facilitate instrumentation
* Make the in_memory adapter actually support multiple subscriptions per destination
    * This is a breaking change if you depended on the old behavior!

## 0.6.1 - 2016-01-28

* fix an issue that prevents gems built under ruby 2.3.0 to be installed
  under ruby 2.3.0 by rebuilding the gem under ruby 2.2

## 0.6.0 - 2016-01-28

* official support for bunny 2.x
* support ruby 2.3
* drop support for bunny < 1.7
* improved API documentation (still a WIP)
* fix an issue with confirm_and_wait transactions erroring because there
  was no open channel

## 0.5.3 - 2014-10-23

* In bunny adapter, avoid sending a tx_commit if we haven't done anything requiring
  a commit inside the transaction block.

## 0.5.2 - 2014-10-14

* fix deprecation warning with bunny 1.5.0

## 0.5.1 - 2014-10-08

* put version constant under correct module

## 0.5.0 - 2014-09-17

* add support for checking consumer counts on a queue in bunny and in_memory adapters
* in_memory adapter now supports multiple subscribers per queue, and does a round-robin
  through them when sending messages to consumers
* upgrade to rspec 3
* Middleware can now be used to automatically pre/post-process messages as they are published to
  or consumed from a destination

## 0.4.0 - 2014-07-03

* require bunny 1.2.2 or later
* add support for publish confirmations

## 0.3.0 - 2014-02-26

* Support for handling multiple broker connections
* require bunny 1.1.3 or later
* make bunny connections as lazily initialized as possible
* bunny transactions start lazily

## 0.2.2 - 2014-02-21

* Lots of work on reconnection handling for bunny. Still a work in
  progress.

## 0.2.1 - 2013-11-13

* Correct an issue in handling Bunny::ConnectionLevelErrors.
  Bunny::Session will now get properly restarted.

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
