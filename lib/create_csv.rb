require 'json'
require 'csv'
require 'date'
require 'securerandom'
require 'stringio'

CSV_DATE_FMT = '%m/%d/%Y %H:%M'
SIZE_PROPERTIES = ['tops', 'sports-bra', 'leggings', 'sports-jacket']
HEADERS = ["order_number","groupon_number","order_date","merchant_sku_item","quantity_requested","shipment_method_requested","shipment_address_name","shipment_address_street","shipment_address_street_2","shipment_address_city","shipment_address_state","shipment_address_postal_code","shipment_address_country","gift","gift_message","quantity_shipped","shipment_carrier","shipment_method","shipment_tracking_number","ship_date","groupon_sku","custom_field_value","permalink","item_name","vendor_id","salesforce_deal_option_id","groupon_cost","billing_address_name","billing_address_street","billing_address_city","billing_address_state","billing_address_postal_code","billing_address_country","purchase_order_number","product_weight","product_weight_unit","product_length","product_width","product_height","product_dimension_unit","customer_phone","incoterms","hts_code","3pl_name","3pl_warehouse_location","kitting_details","sell_price","deal_opportunity_id","shipment_strategy","fulfillment_method","country_of_origin","merchant_permalink","feature_start_date","feature_end_date","bom_sku","payment_method","color_code","tax_rate","tax_price"]

def load_csv(filename)
  csv = CSV.new(File.open(filename, 'r'), headers: :first_row).read
  csv.map(&:to_h)
end

def load_multiple_product_data(filename)
  load_csv(filename).map do |row|
    row.merge({
      'product_id' => row['product_id'].to_i,
    })
  end
end

def load_size_sku_data(filename)
  load_csv(filename).map do |row|
    row.merge({
      'product_item' => row['product_item'].downcase.tr(' ', '-'),
      'product_id' => row['product_id'].to_i,
    })
  end
end

MULTIPLE_PRODUCT_DATA = load_multiple_product_data('data/multi_line_item_product.csv')
SIZE_SKU_DATA = load_size_sku_data('data/sku_sizes.csv')

# IMPORTANT COLUMN INDEX REFERENCE FOR CSV:
# 0 order number
# 2 order date
# 3 merchant sku
# 4 quantity requested
# 6 customer name
# 7 shipping address
# 8 shipping address2
# 9 shipping address city
# 10 shipping address state
# 11 shipping address zipcode
# 12 shipping address country
# 23 item name
# 24 vendor id
# 27 billing name
# 28 billing address
# 29 billing city
# 30 billing state
# 31 billing zip
# 32 billing country
# 34 product weight (only for boxes)
# 35 product weight unit
# 40 customer phone number
# 46 sell price

def unprocessed_orders
  # get all unfulfilled orders
  my_shopify_orders = ShopifyOrder
    .where('created_at BETWEEN ? AND ?', Time.zone.local(2017, 12, 27, 0, 0), Time.current)
    .where('json_array_length(fulfillments) = 0')

  puts "** Number of orders to fulfill: #{my_shopify_orders.length} **"
  puts "*************"

  my_shopify_orders
end

def to_row_hash(order)
  billing_address = order.billing_address
  shipping_address = order.shipping_address
  line_items = order.line_item
  # for each ShopifyOrder in DB, create at least one 'order' -- if ShopifyOrder only had one line item, only one order will be created, while multiple orders (CSV rows) will be created if the ShopifyOrder contains multiple line items
  expanded_line_items = line_items.flat_map{|item| map_multiple_products(MULTIPLE_PRODUCT_DATA, SIZE_SKU_DATA, item)}
  expanded_line_items.map do |line_item|
    {
      'order_number' => order.name,
      'order_date' => order.processed_at.strftime(CSV_DATE_FMT),
      'customer_phone' => billing_address["phone"].try('gsub', /[^0-9]/, ''),
      'tax_rate' => line_item['taxable'] ? line_item['tax_lines'].pluck('rate').sum * 100 : 0,
      'tax_price' => line_item['taxable'] ? line_item['tax_lines'].pluck('price').map(&:to_f).sum : 0,
      'sell_price' => line_item['price'],
      'shipment_method_requested' => (shipping_mapping order.shipping_lines.first['code'] rescue 'GROUND'),
      'quantity_requested' => line_item['quantity'],
      'merchant_sku_item' => line_item['sku'],
      'product_weight' => line_item['grams'],
      'item_name' => line_item['title'],
      'billing_address_name' => billing_address["name"],
      'billing_address_street' => billing_address["address1"],
      'billing_address_city' => billing_address["city"],
      'billing_address_postal_code' => billing_address["zip"],
      'billing_address_state' => billing_address["province_code"],
      'billing_address_country' => billing_address["country_code"],
      'shipment_address_name' => "#{shipping_address["first_name"]} #{shipping_address["last_name"]}",
      'shipment_address_street' => shipping_address["address1"],
      'shipment_address_street_2' => shipping_address["address2"],
      'shipment_address_city' => shipping_address["city"],
      'shipment_address_postal_code' => shipping_address["zip"],
      'shipment_address_state' => shipping_address["province_code"],
      'shipment_address_country' => shipping_address["country_code"],
      'gift' => 'false',
    }
  end
end

def name_csv
  "Orders_#{Time.current.strftime("%Y_%m_%d_%H_%M_%S_%L")}.csv"
end

def create_csv(orders_list)
  # create empty CSV file with appropriate name
  filename = '/tmp/' + name_csv
  orders = orders_list.flat_map{|order| to_row_hash(order)}
  puts "#{orders.length} Order line items"
  file = CSV.open(filename, 'w', headers: HEADERS) do |csv|
    csv << HEADERS
    orders.each{|data| csv << HEADERS.map{|key| data[key]} }
  end
  puts "wrote to #{filename}"
  file
end

def map_multiple_products(multiple_product_data, size_sku_data, line_item)
  multi_product_ids = multiple_product_data.pluck('product_id').map(&:to_i)
  return [line_item] unless multi_product_ids.include? line_item['product_id']
  # check if item has size properties

  prop_hash = line_item['properties']
    .map{|p| [p['name'], p['value']]}
    .to_h

  sizes = prop_hash.select{|k, _| SIZE_PROPERTIES.include? k}

  #puts sku_data.inspect

  line_item_skus = size_sku_data
    .select{|row| row['product_id'].to_s == line_item['product_id'].to_s}
    .select{|row| row['size'] == 'ONE SIZE' || row['size'] == sizes[row['product_item']]}

  output_items = line_item_skus.map{|data| {
    'product_id' => data['product_id'],
    'sku' => data['sku'],
    'title' => data['item_name'],
    'tax_lines' => [],
    'grams' => 0,
    'taxable' => false,
    'price' => 0,
    'properties' => prop_hash.merge({
      'main-product' => false,
    }).map{|k,v| {'name' => k, 'value' => v}},
  }}

  #if output_items.length > 0
    #puts "DETECTED MULTI ITEM PRODUCT: #{line_item['product_id']} #{line_item['title']}"
    #puts "added #{output_items.length}"
  #end

  #puts "mapped #{output_items}"
  output_items.map{|skus| line_item.merge(skus)} + [line_item]
end

def shipping_mapping(code)
  mapping = {
    'Free Shipping (5-9 days)' => 'GROUND',
    'Standard Shipping (6-9 days)' => 'GROUND',
    'custom' => 'GROUND',
    'Express Shipping (1-2 days)' => 'PRIORITY 2',
  }
  mapping[code] || 'GROUND'
end

def generate_order_number
  "#IN" + SecureRandom.random_number(36**12).to_s(36).rjust(11,"0")
end

def map_user_sizes(user,type)
  mapping = {
    'Leggings' => user.bottom_size.upcase,
    'Sports Bra' => user.bra_size.upcase,
    'Jacket' => user.sports_jacket_size.upcase,
    'Tops' => user.top_size.upcase,
    'Equipment' => 'ONE SIZE',
    'Accessories' => 'ONE SIZE',
    'Wrap' => 'ONE SIZE'
   }
  mapping[type]
end

def create_output_csv(orders)
  filename = '/tmp/' + name_csv
  CSV.open(filename, 'w', headers: HEADERS) do |csv|
    csv << HEADERS
    orders.each do |order|
      influencer = Influencer.find(order.influencer_id)
      data_out = [
          order.name, #0
          "", #1
          order.processed_at.try(:strftime, CSV_DATE_FMT), #2
          order.line_item['merchant_sku_item'], #3
          1, #4
          "", #5
          order.shipping_address['name'], #6
          order.shipping_address['address1'], #7
          order.shipping_address['address2'], #8
          order.shipping_address['city'], #9
          order.shipping_address['province_code'], #10
          order.shipping_address['zip'], #11
          order.shipping_address['country_code'], #12
          "FALSE", #13
          "", #14
          "", #15
          "", #16
          "", #17
          "", #18
          "", #19
          "", #20
          "", #21
          "", #22
          order.line_item["item_name"], #23
          "", #24
          "", #25
          "", #26
          order.billing_address['name'], #27
          order.billing_address['address1'], #28
          order.billing_address['city'], #29
          order.billing_address['province_code'], #30
          order.billing_address['zip'], #31
          order.billing_address['country_code'], #32
          "", #33
          order.line_item['product_weight'], #34
          "", #35
          "", #36
          "", #37
          "", #38
          "", #39
          influencer.phone.try('gsub', /[^0-9]/, ''), #40
          "", #41
          "", #42
          "", #43
          "", #44
          "", #45
          order.line_item['sell_price'], #46
          "", #47
          "", #48
          "", #49
          "", #50
          "", #51
          "", #52
          "", #53
          "", #54
          "", #55
          "", #56
          "", #57
        ]
        puts 'order out'
        csv << data_out
    end
  end
  filename
end
