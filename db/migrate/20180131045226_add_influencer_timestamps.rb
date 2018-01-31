class AddInfluencerTimestamps < ActiveRecord::Migration[5.1]
  def up
    remove_column :influencers, :three_item, :boolean
    add_column :influencers, :created_at, :timestamp
    add_column :influencers, :updated_at, :timestamp
  end

  def down
    add_column :influencers, :three_item, :boolean, null: false, default: false
    remove_column :influencers, :created_at
    remove_column :influencers, :updated_at
  end
end
