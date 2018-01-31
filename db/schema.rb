# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180131013916) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "influencer_orders", force: :cascade do |t|
    t.string "name"
    t.datetime "processed_at"
    t.jsonb "billing_address"
    t.jsonb "shipping_address"
    t.jsonb "shipping_lines"
    t.jsonb "line_item"
    t.integer "influencer_id"
    t.datetime "uploaded_at"
    t.string "shipment_method_requested"
  end

  create_table "influencer_tracking", force: :cascade do |t|
    t.bigint "order_id"
    t.string "carrier"
    t.string "tracking_number"
    t.datetime "email_sent_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "influencers", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "email"
    t.string "phone"
    t.string "bra_size"
    t.string "top_size"
    t.string "bottom_size"
    t.string "sports_jacket_size"
    t.boolean "three_item"
  end

  create_table "shopify_collects", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "collection_id"
    t.datetime "created_at"
    t.boolean "featured"
    t.integer "position"
    t.bigint "product_id"
    t.string "sort_value"
    t.datetime "updated_at"
  end

  create_table "shopify_custom_collections", id: :bigint, default: nil, force: :cascade do |t|
    t.text "body_html"
    t.string "handle"
    t.string "image"
    t.json "metafield"
    t.boolean "published"
    t.datetime "published_at"
    t.string "published_scope"
    t.string "sort_order"
    t.string "template_suffix"
    t.string "title"
    t.datetime "updated_at"
  end

  create_table "shopify_orders", id: :bigint, default: nil, force: :cascade do |t|
    t.bigint "app_id"
    t.json "billing_address"
    t.string "browser_ip"
    t.boolean "buyer_accepts_marketing"
    t.datetime "cancelled_at"
    t.string "cancel_reason"
    t.string "cart_token"
    t.bigint "checkout_id"
    t.string "checkout_token"
    t.datetime "closed_at"
    t.boolean "confirmed"
    t.string "contact_email"
    t.datetime "created_at"
    t.float "currency"
    t.json "customer"
    t.string "customer_locale"
    t.bigint "device_id"
    t.json "discount_codes"
    t.string "email"
    t.string "financial_status"
    t.json "fulfillments"
    t.string "fulfillment_status"
    t.string "gateway"
    t.string "landing_site"
    t.string "landing_site_ref"
    t.json "line_items"
    t.bigint "location_id"
    t.string "name"
    t.text "note"
    t.json "note_attributes"
    t.integer "number"
    t.integer "order_number"
    t.string "order_status_url"
    t.json "payment_gateway_names"
    t.string "phone"
    t.datetime "processed_at"
    t.string "processing_method"
    t.string "reference"
    t.string "referring_site"
    t.json "refunds"
    t.json "shipping_address"
    t.json "shipping_lines"
    t.string "source_identifier"
    t.string "source_name"
    t.string "source_url"
    t.float "subtotal_price"
    t.string "tags"
    t.boolean "taxes_included"
    t.json "tax_lines"
    t.boolean "test"
    t.string "token"
    t.float "total_discounts"
    t.float "total_line_items_price"
    t.float "total_price"
    t.float "total_price_usd"
    t.float "total_tax"
    t.integer "total_weight"
    t.datetime "updated_at"
    t.bigint "user_id"
    t.datetime "sent_to_acs_at"
  end

  create_table "shopify_product_variants", id: :bigint, default: nil, force: :cascade do |t|
    t.string "barcode"
    t.float "compare_at_price"
    t.datetime "created_at"
    t.string "fulfillment_service"
    t.integer "grams"
    t.bigint "image_id"
    t.string "inventory_management"
    t.string "inventory_policy"
    t.integer "inventory_quantity"
    t.integer "old_inventory_quantity"
    t.integer "inventory_quantity_adjustment"
    t.bigint "inventory_item_id"
    t.boolean "requires_shipping"
    t.json "metafield"
    t.string "option1"
    t.string "option2"
    t.string "option3"
    t.integer "position"
    t.float "price"
    t.bigint "product_id"
    t.string "sku"
    t.boolean "taxable"
    t.string "title"
    t.datetime "updated_at"
    t.integer "weight"
    t.string "weight_unit"
  end

  create_table "shopify_products", id: :bigint, default: nil, force: :cascade do |t|
    t.text "body_html"
    t.datetime "created_at"
    t.string "handle"
    t.json "image"
    t.json "images"
    t.json "options"
    t.string "product_type"
    t.datetime "published_at"
    t.string "published_scope"
    t.string "tags"
    t.string "template_suffix"
    t.string "title"
    t.string "metafields_global_title_tag"
    t.string "metafields_global_description_tag"
    t.datetime "updated_at"
    t.json "variants"
    t.string "vendor"
  end

end
