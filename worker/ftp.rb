require 'net/ftp'
require 'csv'
require_relative '../lib/async'
require_relative '../lib/logging.rb'

class EllieFtp < Net::FTP
  include Async
  include Logging

  @user = nil
  @password = nil
  @host = nil
  @debug = false

  class << self
    attr_accessor :debug, :host, :user, :password
  end

  def self.upload_orders_csv(file, options = {})
    directory = options[:directory] || '/EllieInfluencer/ReceiveOrder'
    ftp = new(self.host, username: self.user, password: self.password, debug_mode: debug)
    logger.info "Starting orders csv upload of #{file} to #{directory} on #{self.host}"
    ftp.chdir directory
    ftp.put(File.open file)
    ftp.close
    logger.info 'Successfully uploaded csv'
  end

  def self.poll_order_tracking(directory = '/EllieInfluencer/SendOrder')
    logger.info "Polling tracking FTP server: #{directory}"
    ftp = new(self.host, username: self.user, password: self.password, debug_mode: self.debug)
    ftp.chdir directory
    dir = ftp.mlsd
    dir.select{|entry| entry.type == 'file' && /^ORDERTRK/ =~ entry.pathname}.each do |entry|
      logger.debug "Found #{entry.pathname}"
      ftp.process_tracking_csv entry.pathname
    end
  end

  def process_tracking_csv(path)
    logger.info "Starting Tracking CSV processing of #{path}"
    tracking_data = get_tracking_csv path

    # add all influencer lines to the database
    # add a send_email job if one has not been sent already
    tracking_data.select{|line| /^#IN/ =~ line['fulfillment_line_item_id']}.each do |tracking_line|
      begin
        tracking = InfluencerTracking
          .create_with(carrier: tracking_line['carrier'], email_sent_at: nil)
          .find_or_create_by(order_name: line['fulfillment_line_item_id'], tracking_number: tracking_line['tracking_1'])
        unless tracking.email_sent?
          logger.info "Sending tracking email to #{tracking.influencer.email}"
          tracking.send_email
        end
      rescue ActiveRecord::RecordNotFound => e
        logger.error e
        next
      end
    end

    # move the processed file to the archive
    begin
      logger.info "Archiving #{path} on FTP server"
      pathname = Pathname.new path
      rename(path, pathname.dirname + 'Archive' + pathname.basename)
    rescue Net::FTPPermError => e
      logger.warn 'Archive file exists already or cannot be overwritten. Removing original.'
      ftp.delete path
    end
  end

  # Retrieves a file and returns the contents as a string
  def gets(remote_file)
    output = ""
    get(remote_file) {|data| output += data}
    output
  end

  def get_tracking_csv(remote_file)
    parse_tracking_csv gets(remote_file)
  end

  private

  def parse_tracking_csv(data)
    csv = CSV.parse(data).map{|line| line.map(&:strip)}
    headers = csv.shift
    csv.map{|line| headers.zip(line).to_h}
  end
end
