vendor = File.expand_path('../vendor', __FILE__)
$:.unshift(vendor) unless $:.include?(vendor)

require 'nesty'

module MessageDriver
  class Error < StandardError; end
  class TransactionError < Error; end
  class TransactionRollbackOnly < TransactionError; end
  class NoSuchDestinationError < Error; end
  class NoSuchConsumerError < Error; end

  class WrappedError < Error
    include Nesty::NestedError
  end
  class QueueNotFound < WrappedError; end
  class ConnectionError < WrappedError; end

end
