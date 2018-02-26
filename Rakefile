require_relative 'config/environment'

require "rake/testtask"
require "sinatra/activerecord/rake"
require 'resque/tasks'

require_relative 'worker/pull'
require_relative 'worker/send_email'
require_relative 'worker/ftp'

def file_input(env_var = 'FILE')
  if ENV['FILE'].nil?
    puts 'Requires FILE for processing. Usage: rake process_tracking FILE=<filepath>'
    exit
  elsif ENV['FILE'] == 'STDIN'
    STDIN
  else
    File.open(ENV['FILE'], 'r')
  end
end

# many if not all of these tasks are called via a cron job. Make sure to update
# the crontab when changing things in the namespace.
namespace :pull do

  desc 'refresh all caches from shopify'
  task :all do |t|
    ShopifyCache.async :pull_all
  end

  desc 'refresh orders cache from shopify'
  task :orders do |t|
    ShopifyCache.async :pull_orders
  end

  desc 'refresh products cache from shopify'
  task :products do |t|
    ShopifyCache.async :pull_products
  end

  desc 'refresh custom collections cache from shopify'
  task :custom_collections do |t|
    ShopifyCache.async :pull_custom_collections
  end

  desc 'refresh collects cache from shopify'
  task :collects do |t|
    ShopifyCache.async :pull_collects
  end

end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.warning = false
  t.verbose = false
  t.test_files = FileList["test/**/*_test.rb"]
end

task :default => :test

task 'resque:setup' do
  ENV['QUEUE'] = '*'
end

desc 'create orders csv'
task :create_csv do |t|
  create_csv(unprocessed_orders)
end

desc 'create tracking from csv'
task :process_tracking do |t|
  OrderTracking.process_tracking_csv file_input
end

desc 'send tracking email. Usage: `rake send_email TRACKING_ID=<ID>`'
task :send_email do |t|
  unless ENV['TRACKING_ID']
    raise ArgumentError.new 'Requires TRACKING_ID. Usage: `rake send_email TRACKING_ID=<ID>`'
  end
  Resque.enqueue(SendEmail, ENV['TRACKING_ID'])
end

# if this is changed be sure to update the crontab
desc 'poll order tracking ftp server. Optional FTP_PATH. Usage: `rake poll_order_tracking [FTP_PATH=/my/path]`'
task :poll_order_tracking do
  path = ENV['FTP_PATH'] || 'EllieInfluencer/SendOrder'
  EllieFtp.async :poll_order_tracking, path
end
