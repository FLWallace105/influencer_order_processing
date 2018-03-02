ENV['RUBY_ENV'] = 'testing'
ENV['RAILS_ENV'] = 'testing'
ENV['RACK_ENV'] = 'testing'
require_relative '../config/environment'

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require 'minitest/autorun'
require 'rack/test'
require 'active_support/test_case'
require 'minitest/hooks/test'
require 'mocha/test_unit'
require 'active_record/fixtures'


# setup the testing database
test_db_lock = APP_ROOT.join('.testing_db.lock')
fixtures = APP_ROOT.join('test', 'fixtures').glob('*.yml')
schema = APP_ROOT.join('db', 'schema.rb')
fixtures_current = fixtures.map(&:mtime).max < test_db_lock.mtime
schema_current = schema.mtime < test_db_lock.mtime
unless test_db_lock.exist? && schema_current && fixtures_current
  Rake.load_rakefile(APP_ROOT.join('Rakefile'))
  Rake::Task['db:drop'].invoke
  Rake::Task['db:setup'].invoke
  puts 'Loading fixtures'
  Rake::Task['db:fixtures:load'].invoke
  test_db_lock.write ''
end

# Include this module to make all database calls rollback at the end of each
# test method.
module TransactionalDB
  include Minitest::Hooks

  def around_all
    ActiveRecord::Base.transaction do
      super
      raise ActiveRecord::Rollback
    end
  end
end
