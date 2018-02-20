require 'sinatra/basic_auth'

$apikey = ENV['SHOPIFY_API_KEY']
$password = ENV['SHOPIFY_PASSWORD']
$shopname = ENV['SHOPIFY_SHOP_NAME']
$secret = ENV['SHOPIFY_SHARED_SECRET']

#ShopifyAPI::Base.site = "https://#{$apikey}:#{$password}@#{$shopname}.myshopify.com/admin"
#ShopifyAPI::Session.setup(api_key: $apikey, secret: $secret)

class DebugError < StandardError; end

class App < Sinatra::Base
  register Sinatra::ActiveRecordExtension
  register Sinatra::BasicAuth

  include ViewHelper

  configure do
    # by default, sinatra assumes that the root is the file that calls the configure block.
    # since this is not the case for us, we set it manually.
    set :root, APP_ROOT.to_path
    # see: http://www.sinatrarb.com/faq.html#sessions
    enable :sessions
    set :session_secret, ENV['session_secret'] || 'this is a secret shhhhh'

    enable :method_override
    # set the views directory to /app/views
    set :views, File.join(App.root, 'app', 'views')
    set :public_folder, APP_ROOT.join('app', 'static').to_path
    #use PryRescue::Rack
  end

  authorize "Admin" do |username, password|
    username == ENV['AUTH_USERNAME'] && password == ENV['AUTH_PASSWORD']
  end

  protect "Admin" do

    get '/' do
      #notifications << Notification.new('test message', type: :warning, header: 'Hello World')
      erb :'index'
    end

    # form to upload a csv containing influencer informatiion
    get '/admin/uploads/new' do
      erb :'uploads/new'
    end

    # form target for influencer order csv
    post '/admin/uploads' do
      begin
        influencer_data = params[:file][:tempfile].read
      rescue NoMethodError => e
        puts params.pretty_inspect
        notifications << Notification.new('Must provide a file to upload')
        redirect '/admin/uploads/new'
      end
      utf_data = influencer_data.force_encoding('iso8859-1').encode('utf-8')
      #rows = CSV.parse(utf_data, headers: true, header_converters: :symbol)
      rows = CSV.parse(utf_data)
      influencers = rows.map{|row| Influencer.from_csv_row(row)}
      errors = influencers.flat_map do |i|
        if i.valid?
          i.save
          next []
        end
        message = i.errors.full_messages.join("\n")
        [Notification.new(message, header: "#{i.name} has errors", type: 'error')]
      end

      if errors.empty?
        notifications << Notification.new("#{influencers.count} successfully uploaded", header: 'Influencers Uploaded', type: 'success')
        redirect '/'
      else
        status 422
        errors.each{|error| notifications << error}
        redirect '/admin/uploads/new'
      end
    end

    get '/admin/influencers' do
      @title = 'Influencers'
      influencer_params = model_params Influencer
      @influencers = if influencer_params.empty?
                       Influencer.all.order(:last_name) 
                     else
                       Influencer.where(influencer_params).order(:last_name)
                     end
      erb :'influencers/index'
    end

    get '/admin/influencers/new' do
      @title = 'Add New Influencer'
      @method = 'post'
      @influencer = Influencer.new
      erb :'influencers/form'
    end

    post '/admin/influencers' do
      case params[:action]
      when 'create_orders'
        #raise DebugError
        influencers = Influencer.where(id: params[:ids])
        # ensure the collection exists
        collection = CustomCollection.find params[:collection_id]
        new_orders = influencers.flat_map do |influencer|
          influencer.create_orders_from_collection collection.id
        end
        msg = "Successfully created orders for #{influencers.count} influencers!"
        notifications << Notification.new(msg, type: 'success')
        ids_query_string = {id: new_orders.pluck{:id}}.to_query
        redirect "/admin/orders?#{ids_query_string}"
      when 'delete'
        raise DebugError
      else
        notifications << Notification.new('Unknown action.', type: 'error')
        redirect '/'
      end
    end

    get '/admin/influencers/delete' do
      @title = 'Reset All Influencers'
      erb :'influencers/delete'
    end

    delete '/admin/influencers' do
      Influencer.destroy_all
      redirect '/'
    end

    get '/admin/influencers/:id' do |id|
      @title = 'Edit Influencer'
      @method = 'put'
      @influencer = Influencer.find id
      erb :'influencers/form'
    end

    # download a csv with influencer information, matches upload format
    get '/admin/influencers/download' do
      file_to_download = Influencer.to_csv
      send_file(file_to_download, :filename => file_to_download)
    end

    # ORDERS

    # used to generate new orders for existing influencers
    post '/admin/influencers/orders' do
      raise DebugError
      return 400 unless params[:collection_id]
      collection = CustomCollection.find params[:collection_id]
      ids = params[id] || []
      influencers = ids.empty? ? Influencer.all : Influencer.where(id: ids)
      influencers.each do |influencer|
        influencer.create_orders_from_collection
      end
    end

    get '/admin/orders' do
      #raise 'debug'
      filter_params = params['filter'] || []
      limit = params['limit'] || 50
      page = params['page'] || 1
      sort_str = sort_params(params, 'influencer_orders', 'uploaded_at', 'desc')
      order_params = model_params InfluencerOrder

      page = InfluencerOrder.select('DISTINCT name')
        .paginate(page: page, limit: limit)
      orders = InfluencerOrder.where(name: page.results.pluck(:name))
        .joins(:influencer, :tracking).order(sort_str)
      orders = filter(filter_params, orders)

      if request.accept? 'test/html'
        @title = 'Influencer Orders'
        @page = page
        @table = orders.group_by(&:name).map do |k, line_items|
          fline = line_items.first
          # set default blank objects if the associated influencer or tracking are
          # not found to avoid errors
          influencer = fline.influencer || Influencer.new
          tracking = fline.tracking || InfluencerTracking.new
          OpenStruct.new(
            ids: simple_format(line_items.pluck(:id).join(", ")),
            order_created_at: simple_format(fline.created_at.to_s),
            order_updated_at: simple_format(fline.updated_at.to_s),
            order_number: simple_format(fline.name),
            processed_at: simple_format(fline.processed_at.iso8601),
            billing_address: fline.billing_address,
            formatted_billing_address: simple_format(format_address(fline.billing_address)),
            shipping_address: fline.shipping_address,
            formatted_shipping_address: simple_format(format_address(fline.shipping_address)),
            line_items: line_items.pluck(:line_item),
            formatted_line_items: simple_format(line_items.pluck(:line_item).pluck('item_name').join("\n")),
            influencer: influencer,
            influencer_name: "#{influencer.first_name} #{influencer.last_name}",
            uploaded_at: fline.uploaded_at,
            shipment_method_requested: fline.shipment_method_requested,
            tracking: tracking,
            tracking_number: tracking.try(:tracking_number),
            carrier: tracking.try(:carrier),
            tracking_created: tracking.created_at.try(:iso8601),
          )
        end
        erb :'orders/index'
      else
        json_obj = orders.map{|o| o.as_json.merge(influencer: o.influencer)}
        return json_response({orders: json_obj, page: page.page, page_count: page.count})
      end
    end

    get '/admin/orders/new' do
      erb :'orders/new'
    end

    post '/admin/orders/upload' do
      order_params = model_params InfluencerOrder
      orders = if order_params.empty? 
                 InfluencerOrder.where(uploaded_at: nil).order(:name)
               else
                 InfluencerOrder.where(order_params).order(:name)
               end
      # Collect the list here because otherwise active record will keep running
      # selects. This could potentially cause a race condition where orders are
      # selected, uploaded, more unsent orders are added and they are all marked
      # as uploaded.
      orders_list = orders.to_a
      if orders_list.count > 0
        csv_file = InfluencerOrder.create_csv orders_list
        queued = Resque.enqueue_to 'default', 'EllieFtp', :upload_orders_csv, csv_file
      else
        queued = false
      end
      # todo: orders should really not be marked uploaded until the upload succeeds.
      # This should be retooled in the future
      if queued && orders_list.count > 0
        InfluencerOrder.where(id: orders_list.pluck(:id)).update_all(uploaded_at: Time.current)
        notifications << Notification.new("#{orders.count} orders sent to the warehouse.",
                                          header: 'Orders Sent', type: 'success')
      elsif queued && orders_list == 0
        notifications << Notification.new('No orders were sent to the warehouse',
                                          header: 'No Orders to Send')
      else
        notifications << Notification.new('Orders were not able to be sent to the warehouse.',
                                          header: 'Error', type: 'warning')
      end
      redirect '/'
    end

    post '/admin/orders' do
      raise DebugError
    end

    get '/admin/orders/download_unprocessed' do
      orders = InfluencerOrder.where(:processed_at => nil)
      file = create_output_csv(orders)
      send_file(file, :filename => "TEST_unprocessed_#{Time.current.strftime("%Y_%m_%d_%H_%M_%S")}.csv")
    end

    # get '/admin/orders/show_processed' do
    #
    # end

    get '/admin/orders/delete' do
      @title = 'Clear All Orders'
      erb :'orders/delete'
    end

    delete '/admin/orders' do
      InfluencerOrder.destroy_all
      redirect '/'
    end

    # ftp

    get '/admin/ftp' do
      erb :ftp
    end

    post '/admin/ftp' do
      orders = InfluencerOrder.where.not(uploaded_at: nil)
      csv_file = create_output_csv orders
      EllieFtp.async :upload_orders_csv, csv_file
    end

    post '/admin/refresh_cache' do
      case params['cache']
      when 'all'
        ShopifyCache.async :pull_all
        erb success ? 'Success' : 'Failure'
      when 'products'
        ShopifyCache.async :pull_products
        erb success ? 'Success' : 'Failure'
      when 'orders'
        ShopifyCache.async :pull_orders
        erb success ? 'Success' : 'Failure'
      when 'collects'
        ShopifyCache.async :pull_collects
        erb success ? 'Success' : 'Failure'
      when 'custom_collections'
        success = ShopifyCache.async :pull_custom_collections
        erb success ? 'Success' : 'Failure'
      else
        404
      end
    end

    get '/debug' do
      raise DebugError
    end

    options '/dump' do
      raise DebugError
    end

    post '/dump' do
      raise DebugError
    end

    patch '/dump' do
      raise DebugError
    end

    delete '/dump' do
      raise DebugError
    end
  end

  error ActiveRecord::RecordNotFound do
    error = env['sinatra.error']
    erb error.message
  end

  private

  def json_response(object, status: 200, headers: {})
    all_headers = {'Content-Type' => 'application/json'}.merge headers
    [status, all_headers, object.to_json]
  end

  def model_params(model)
    model.column_names.map{|col| params.assoc col}.reject(&:nil?).to_h
  end

  def notifications
    session[:notifications] ||= []
  end

  def notifications=(other)
    session[:notifications] = other
  end

  def render_and_clear_notifications
    notifications.pop(notifications.length)
  end

  # creates a string safe for passing to #order()
  def sort_params(params, default_sort_table, default_sort_by, default_sort_dir)
    clean_field_re = /[^_A-Za-z0-9]/
    sort_table = params['sort_table'].try(:gsub, clean_field_re, '') || default_sort_table
    sort_by = params['sort_by'].try(:gsub, clean_field_re, '') || default_sort_by
    sort_dir = params['sort_dir'] || default_sort_dir
    #sort_obj = {(params['sort_table'] || 'orders') => {(params['sort_by'] || 'orders') => (params['sort_dir'] || 'ASC')}}
    if sort_table
      "#{sort_table}.#{sort_by} #{sort_dir}"
    else
      "#{sort_by} #{sort_dir}"
    end
  end

  def filter(filter_params, query)
    ops = {
      'gt' => '>',
      'gte' => '>=',
      'lt' => '<',
      'lte' => '<=',
      'eq' => '=',
      'is' => 'is',
      'like' => 'LIKE',
      'in' => 'IN',
    }
    filter_params.reduce(query) do |filter|
      sql_obj_re = /[^A-Za-z0-9_]/
      where_query = ""
      table = filter.table.gsub(sql_obj_re, '') rescue ''
      where_query += "#{table}." unless table.empty?
      where_query += "#{filter.column}"
      where_query += " #{ops[filter.op] || '='} ?"
      query.where(where_query, filter.val)
    end
  end

end
