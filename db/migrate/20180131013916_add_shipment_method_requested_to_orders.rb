class AddShipmentMethodRequestedToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :influencer_orders, :shipment_method_requested, :string
  end
end
