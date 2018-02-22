class Product < ApplicationRecord
  self.table_name = 'shopify_products'

  has_many :variants, class_name: 'ProductVariant'
  has_many :collects
  has_many :collections, through: 'collects'

  def size_variant(size)
    variants.find_by(option1: size)
  end
end
