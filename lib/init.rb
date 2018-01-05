require 'bundler'
Bundler.require(:default, ENV['RACK_ENV'])
Dotenv.load
Dir[File.dirname(__FILE__) + '/../lib/**/*.rb'].each do |file|
  require file
end
