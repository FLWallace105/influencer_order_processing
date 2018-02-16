module ApplicationRecord

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    
    def page(page, per: 25)
      limit(per).offset(page * per)
    end

  end
end
