source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem 'activerecord'
gem 'activesupport'
gem 'connection_pool'
gem "dotenv", "~> 2.2"
gem 'httparty'
gem 'iconv' # for translating utf8 to ascii for ACS csv
gem 'pg', '~>0.18'
gem 'puma'
gem 'rake'
gem 'recharge-api'
gem 'redis'
gem 'resque'
gem 'searchkick'
gem 'sendgrid-ruby'
gem 'shopify_api'
gem "shopify-api-throttle", git: 'https://github.com/bradrees/shopify-api-throttle.git'
gem 'sinatra-activerecord'
gem 'sinatra-basic-auth', require: 'sinatra/basic_auth'
gem 'sinatra', require: 'sinatra/base'

group :development, :testing do
  gem 'pry'
  gem 'pry-stack_explorer'
  gem 'pry-rescue'
  gem 'faker'
end

group :development do
  gem 'shotgun'
  # docs
  gem 'yard'
  gem 'yard-sinatra'
  gem 'yard-activerecord'
  gem 'redcarpet'
end

group :testing do
  gem 'rack-test'
  gem 'mocha'
  gem 'minitest-hooks'
end

