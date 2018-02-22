class Collect < ApplicationRecord
  self.table_name = 'shopify_collects'

  belongs_to :product
  belongs_to :collection, class_name: 'CustomCollection'
end

