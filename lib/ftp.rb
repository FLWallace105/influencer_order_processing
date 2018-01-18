require 'net/ftp'
require 'csv'
require_relative 'async'

class EllieFtp < Net::FTP
  include Async

  def self.upload_orders_csv(file, options = {})
    directory = options[:directory] || 'ReceiveOrder'
    ftp = new(ENV['FTP_HOST'], username: ENV['FTP_USER'], password: ENV['FTP_PASSWORD'], debug_mode: true)
    ftp.chdir directory
    ftp.put(File.open file)
    puts 'i put it!'
    ftp.close
  end

  def self.poll_order_tracking(directory = '/SendOrder')
    ftp = new(ENV['FTP_HOST'], username: ENV['FTP_USER'], password: ENV['FTP_PASSWORD'], debug_mode: true)
    ftp.chdir directory
    dir = ftp.mlsd
    dir.select{|entry| entry.type == 'file' && /^ORDERTRK/ =~ entry.pathname}.each do |entry|
      ftp.process_tracking_csv entry.pathname
    end
  end

  def process_tracking_csv(path)
    tracking_data = get_tracking_csv path

    # add all influencer lines to the database
    # add a send_email job if one has not been sent already
    binding.pry
    tracking_data.select{|line| /^#IN/ =~ line['fulfillment_line_item_id']}.each do tracking_line
      order = InfluencerOrder.find_by!(name: tracking_line['fulfillment_line_item_id'])
      tracking = InfluencerTracking
        .create_with(carrier: tracking_line['carrier'], email_sent_at: nil)
        .find_or_create_by(order_id: order.id, tracking_number: tracking_line['tracking_1'])
      Resque.enqueue(SendEmail, order.influencer_id, tracking.email_data) unless tracking.email_sent?
    end

    # move the processed file to the archive
    pathname = Pathname.new path
    rename(path, pathname.dirname + 'Archive' + pathname.basename)
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
