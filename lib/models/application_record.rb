require_relative '../paginate.rb'
require_relative '../async'
require_relative '../logging'

class ApplicationRecord < ActiveRecord::Base
  include Async
  include Logging

  self.abstract_class = true

  # Allow reindexing a subset of records. Useful for calling in combination with
  # async. Passes all arguments to ::where
  def self.reindex_where(*args, **kwargs)
    where(*args, **kwargs).each(&:reindex)
  end

  # Reindex all records asynchronously in Elasticsearch.
  #
  # When you use `searchkick callbacks: :async` it sets up all the appropriate
  # activerecord callback to call the ::reindex_async method. We redefine this
  # method to take advantage of resque instead of the built in ::reindex_async
  # which depends on ActiveJob.
  #
  # See the [searchkick source](https://github.com/ankane/searchkick/blob/5b77618a0fb11053c56475bfe9609540807b3a90/lib/searchkick/model.rb#L80)
  def self.reindex_async
    async :reindex
  end

  # reindex a single record asynchronously
  def reindex_async
    self.class.async :reindex_where, id: id
  end

  # Return a Paginate object for the current query
  def self.paginate(page: 1, limit: 50)
    Paginate.new self, page: page, limit: limit
  end

end
