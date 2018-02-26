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
if File.exist?(ENV['BUNDLE_GEMFILE'])
  original_verbosity = $VERBOSE
  $VERBOSE = nil
  require 'bundler'
  Bundler.require(:default, ENVIRONMENT)
  $VERBOSE = original_verbosity
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

def load_yml(path)
  b = binding
  Psych.load(ERB.new(File.open(path.to_s, 'r').read).result(b))
end

autoload_path APP_ROOT.join('app', 'helpers', '*.rb')

# Set up the database and models
require APP_ROOT.join('config', 'database')
autoload_path APP_ROOT.join('lib', 'models', '*.rb')

# load ftp configuration
require APP_ROOT.join('worker', 'ftp')
ftp_config = load_yml(APP_ROOT.join('config', 'ftp.yml'))[ENVIRONMENT.to_s]
EllieFtp.host = ftp_config['host']
EllieFtp.user = ftp_config['user']
EllieFtp.password = ftp_config['password']

