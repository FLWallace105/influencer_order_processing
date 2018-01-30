# Set up gems listed in the Gemfile.
# See: http://gembundler.com/bundler_setup.html
#      http://stackoverflow.com/questions/7243486/why-do-you-need-require-bundler-setup
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
require 'dotenv'
Dotenv.load

# Set the environment from common ruby environment variables. Default to
# :development environment.
ENVIRONMENT = (ENV['RUBY_ENV'] || ENV['RACK_ENV'] || :development).to_sym

# Require gems we care about
require 'uri'
require 'pathname'
require 'logger'
require 'erb'
if File.exists?(ENV['BUNDLE_GEMFILE'])
  require 'bundler'
  Bundler.require(:default, ENV['RACK_ENV'] || :development)
end

# Some helper constants for path-centric logic
APP_ROOT = Pathname.new(File.expand_path('../../', __FILE__))
APP_NAME = APP_ROOT.basename.to_s

# require any initializers
Dir[APP_ROOT.join('lib', 'initializers', '*.rb')].each do |file|
  require file
end


# require libraries we use everywhere

# setup lazy loading for helpers and models
def autoload_path(path)
  Dir[path].each do |file|
    filename = File.basename(file).gsub('.rb', '')
    class_name = ActiveSupport::Inflector.camelize(filename)
    #puts "lazy loading #{class_name} in #{file}"
    autoload class_name, file
  end
end

autoload_path APP_ROOT.join('app', 'helpers', '*.rb')

# Set up the database and models
require APP_ROOT.join('config', 'database')
autoload_path APP_ROOT.join('lib', 'models', '*.rb')
