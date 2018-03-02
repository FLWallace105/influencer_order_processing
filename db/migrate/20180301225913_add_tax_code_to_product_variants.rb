class AddTaxCodeToProductVariants < ActiveRecord::Migration[5.1]
  def change
    add_column :shopify_product_variants, :tax_code, :string, null: false
  end
end
