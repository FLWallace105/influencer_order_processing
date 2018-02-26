# Represents a order within shopify. This is a cached, readonly class. Changes
# here will not be reflected in Shopify.
class ShopifyOrder < ApplicationRecord
  self.table_name = 'shopify_orders'
end
