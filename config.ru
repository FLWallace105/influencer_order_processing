require ::File.expand_path('../config/environment',  __FILE__)
require_relative 'app/controllers/app_controller'

#set :app_file, __FILE__

run App
