class ProductVariant < ApplicationRecord
  self.table_name = 'shopify_product_variants'

  belongs_to :product

  # for all? of our products the option1 is a size property. alias it as such
  # here so its meaning is convayed throughout the codebase
  def size
    option1
  end

end

