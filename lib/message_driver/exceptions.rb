require 'nesty'

module MessageDriver
  class Exception < StandardError
    include Nesty::NestedError
  end

  class QueueNotFound < Exception; end

  class ConnectionException < Exception; end

  class TransactionRollbackOnly < Exception; end
end
