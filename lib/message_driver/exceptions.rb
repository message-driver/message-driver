require 'nesty'

module MessageDriver
  class Exception < StandardError; end

  class WrappedException < Exception
    include Nesty::NestedError
  end

  class QueueNotFound < WrappedException; end

  class ConnectionException < WrappedException; end

  class TransactionRollbackOnly < Exception; end
end
