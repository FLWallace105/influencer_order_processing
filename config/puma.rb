require_relative 'environment'
environment ENV['RACK_ENV'] || 'development'
bind "tcp://0.0.0.0:9292"
rackup "#{APP_ROOT}/config.ru"
daemonize false
