class InfluencerTracking < ApplicationRecord

  self.table_name = 'influencer_tracking'
  has_many(:orders, class_name: 'InfluencerOrder', foreign_key: 'name',
           primary_key: 'order_name')

  after_commit :reindex_orders

  def influencer
    orders.first.influencer
  rescue
    nil
  end

  def email_data
    {
      influencer_id: order.influencer_id,
      carrier: carrier,
      tracking_num: tracking_number,
    }
  end

  def email_sent?
    !email_sent_at.nil?
  end

  def send_email
    Resque.enqueue_to(:default, 'SendEmail', id)
  end

  def reindex_orders
    InfluencerOrder.async :reindex_where, name: order_name
  end
end
