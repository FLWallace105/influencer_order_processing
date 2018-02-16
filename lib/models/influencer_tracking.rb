class InfluencerTracking < ActiveRecord::Base
  include ApplicationRecord

  self.table_name = 'influencer_tracking'
  has_many(:orders, class_name: 'InfluencerOrder', foreign_key: 'name',
           primary_key: 'order_name')
  has_one :influencer, through: 'order'

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
end
