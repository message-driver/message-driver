@all_adapters
Feature: Stuff gets logged if you set a logger

  You can configure the logger by add a logger to the hash passed to `MessageDriver::Broker.configure`.
  If you don't provide a logger, then an info level logger will be created and sent to `STDOUT`.

  Scenario: Starting the broker
    Given I am logging to a log file at the debug level
    And I am connected to the broker

    Then the log file should contain:
    """
    MessageDriver configured successfully!
    """
