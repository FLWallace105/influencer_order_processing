require_relative '../paginate.rb'
require_relative '../async'

class ApplicationRecord < ActiveRecord::Base
  include Async

  self.abstract_class = true

  def self.reindex_where(*args, **kwargs)
    where(*args, **kwargs).each(&:reindex)
  end

  # whey you use `searchkick callbacks: :async` it sets up all the appropriate
  # activerecord callback to call the ::reindex_async method. We redefine this
  # method to take advantage of resque instead of the built in ::reindex_async
  # which depends on ActiveJob
  # see https://github.com/ankane/searchkick/blob/5b77618a0fb11053c56475bfe9609540807b3a90/lib/searchkick/model.rb#L80
  def self.reindex_async
    async :reindex
  end

  def reindex_async
    self.class.async :reindex_where, id: id
  end

  def self.paginate(page: 1, limit: 50)
    Paginate.new self, page: page, limit: limit
  end

end
