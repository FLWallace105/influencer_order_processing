ENV['RUBY_ENV'] = 'testing'
ENV['RAILS_ENV'] = 'testing'
ENV['RACK_ENV'] = 'testing'
require_relative '../config/environment'

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require 'minitest/autorun'
require 'rack/test'
require 'active_support/test_case'
require 'minitest/hooks/test'
