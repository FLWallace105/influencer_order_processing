class AddInfluencerOrderTimestamps < ActiveRecord::Migration[5.1]
  def change
    add_column :influencer_orders, :created_at, :timestamp
    add_column :influencer_orders, :updated_at, :timestamp
  end
end
