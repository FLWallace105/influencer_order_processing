class Influencer < ActiveRecord::Base
  include ApplicationRecord

  has_many :orders, class_name: 'InfluencerOrder'
  has_many :tracking_info, class_name: 'InfluencerTracking'
  alias :tracking_numbers :tracking_info
  alias :tracking :tracking_info
  
  SIZE_VALUES = %w(XS S M L XL)
  INFLUENCER_HEADERS = ["first_name", "last_name", "address1", "address2", "city", "state", "zip", "email", "phone", "bra_size", "top_size", "bottom_size", "sports_jacket_size", "collection_id", "shipping_method_requested"]
  SIZE_VALIDATION = {
    presence: true,
    inclusion: {
      in: SIZE_VALUES,
      message: "%{value} is not a valid size",
    }
  }

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :address1, presence: true
  validates :city, presence: true
  # use strings that look like 2 letter state abbreviations
  # TODO: will not work for international shipping
  validates :state, presence: true, format: /\A[A-Z]{2}\z/
  # make sure zips follow a 5 or 5 dash 4 digit pattern
  validates :zip, presence: true, format: /\A\d{5}(-\d{4})?\z/
  validates :bra_size, SIZE_VALIDATION
  validates :top_size, SIZE_VALIDATION
  validates :bottom_size, SIZE_VALIDATION
  validates :sports_jacket_size, SIZE_VALIDATION
  validates :email, presence: true


  def self.to_csv
    filename = '/tmp/' + 'current_influencers.csv'
    CSV.open(filename, 'w+', headers: INFLUENCER_HEADERS) do |csv|
      csv << INFLUENCER_HEADERS
      Influencer.all.each do |user|
        csv << INFLUENCER_HEADERS.map do |key|
          user[key]
        end
      end
    end
    filename
  end

  def self.from_csv_row(row, create_orders: true)
    clean_row = row.map(&:strip)
    attributes = {
      first_name: clean_row[0],
      last_name: clean_row[1],
      address1: clean_row[2],
      address2: clean_row[3],
      city: clean_row[4],
      state: clean_row[5],
      zip: clean_row[6],
      email: clean_row[7],
      phone: clean_row[8],
      bra_size: clean_row[9].upcase,
      top_size: clean_row[10].upcase,
      bottom_size: clean_row[11].upcase,
      sports_jacket_size: clean_row[12].upcase,
    }
    influencer = find_or_initialize_by(email: attributes[:email])
    influencer.update(attributes)
    collection_id = clean_row[13]
    if create_orders && influencer.valid? && collection_id
      orders = influencer.create_orders_from_collection collection_id, shipment_method_requested: clean_row[14]
      puts "created #{orders.count} orders for #{influencer.first_name} #{influencer.last_name}"
    end
    influencer
  end

  def sized_variants_from_collection(collection_id)
    product_ids = Collect.where(collection_id: collection_id).pluck(:product_id)
    variants = ProductVariant.where(product_id: product_ids)
    sized_variants = variants.select do |variant|
      variant.size == 'ONE SIZE' || variant.size == sizes[variant.product.product_type]
    end
  end

  def create_orders_from_collection(collection_id, creation_options = {})
    sized_variants = sized_variants_from_collection(collection_id)
    creation_options[:order_number] ||= InfluencerOrder.generate_order_number
    sized_variants.map do |variant|
      InfluencerOrder.create_from_influencer_variant(self, variant, creation_options)
    end
  end

  def sizes
    {
      'Leggings' => bottom_size,
      'Tops' => top_size,
      'Sports Bra' => bra_size,
      'Jacket' => sports_jacket_size,
    }
  end

  def address
    {
      'address1' => address1,
      'address2' => address2,
      'city' => city,
      'zip' => zip,
      'province_code' => state,
      'country_code' => 'US',
      'phone' => phone,
    }
  end

  def shipping_address
    address.merge(
      'first_name' => first_name,
      'last_name' => last_name,
    )
  end

  def billing_address
    address.merge('name' => "#{first_name} #{last_name}")
  end

end
