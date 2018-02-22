class CustomCollection < ApplicationRecord
  self.table_name = 'shopify_custom_collections'

  has_many :collects, foreign_key: 'collection_id'
  has_many :products, through: 'collects'
end
