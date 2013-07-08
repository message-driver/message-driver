require 'nesty'

module MessageDriver
  class Error < StandardError; end
  class TransactionRollbackOnly < Error; end
  class NoSuchDestinationError < Error; end
  class NoSuchConsumerError < Error; end

  class WrappedError < Error
    include Nesty::NestedError
  end
  class QueueNotFound < WrappedError; end
  class ConnectionError < WrappedError; end

end
