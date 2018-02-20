require_relative '../paginate.rb'

module ApplicationRecord

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    
    def paginate(page: 1, limit: 50)
      Paginate.new self, page: page, limit: limit
    end

  end
end
