require 'sendgrid-ruby'
require 'json'
require_relative '../lib/logging'

class SendEmail
  include Logging
  include SendGrid


  @queue = :send_emails

  # task a InfluencerTracking id and sends an email with the appropriate
  # tracking number and carrier
  def self.perform(tracking_id, test: true)
    tracking = InfluencerTracking.find tracking_id
    influencer = tracking.influencer

    begin
      from = Email.new(email: ENV['OUR_EMAIL'], name: 'Ellie')
      subject = "Your order has been shipped!"
      to =
        if test
          sinkhole = influencer.email.split('@')[0] + '@sink.sendgrid.net'
          Email.new(email: sinkhole)
        else
          Email.new(email: influencer.email)
        end

      content = Content.new(type: 'text/plain', value: "#{influencer.first_name}, your order is on its way! Your tracking information is below: \n
      Carrier: #{tracking.carrier} \n
      Tracking Number: #{tracking.tracking_number} \n
      Order Number: #{tracking.order.name}")

      mail = Mail.new(from, subject, to, content)
      logger.info mail.to_json

      sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'], host: 'https://api.sendgrid.com')

      response = sg.client.mail._('send').post(request_body: mail.to_json)
      logger.debug response.status_code
      logger.debug response.body
      logger.debug response.headers
      
      tracking.email_sent_at = Time.current
      tracking.save
      logger.info "** Sent! **"
    rescue Exception => e
      logger.error e
    end

  end
end

klass, args = Resque.reserve(:emails_queue)
klass.perform(*args) if klass.respond_to? :perform
