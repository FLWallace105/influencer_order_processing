# Allow class methods to be called asynchronously via Resque.
module Async
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    # the name of the queue to use
    def queue
      :default
    end

    # Internal method required by Resque. What is actually called by the Resque
    # job.
    def perform(method, *args)
      send(method, *args)
    end

    # Call the given method asynchronously
    #
    # @param method [String, Symbol] The name of the method to be called on this
    #   class asynchronously.
    # @param args Any arguments to be passed to the method when
    #   eventually called. Must be serializable.
    def async(method, *args)
      Resque.enqueue(self, method, *args)
    end
  end
end
