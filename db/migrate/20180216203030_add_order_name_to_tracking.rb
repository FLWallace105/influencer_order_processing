class AddOrderNameToTracking < ActiveRecord::Migration[5.1]
  def self.up
    add_column :influencer_tracking, :order_name, :string, default: 'NONE'

    InfluencerTracking.reset_column_information

    default_name = "NONE"
    InfluencerTracking.all.each do |t|
      order = InfluencerOrder.find(id: t.order_id)
      t.update(order_name: order.name || default_name).save!
    rescue
      next
    end

    change_column :influencer_tracking, :order_name, :string, null: false, default: nil
    remove_column :influencer_tracking, :order_id

    add_index :influencer_tracking, :order_name
    add_index :influencer_orders, :name
  end
end
