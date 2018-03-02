require_relative 'test_helper'
require './worker/ftp'

class FtpTest < Minitest::Test
  include Minitest::Hooks

  @ftp = nil

  class << self
    attr_accessor :ftp
  end

  def before_all
    EllieFtp.debug = true
    ftp = EllieFtp.new
  rescue Exception => e
    STDERR.puts "host: #{EllieFtp.host}"
    STDERR.puts "username: #{EllieFtp.username}"
    STDERR.puts "password: #{EllieFtp.password}"
    STDERR.puts e.backtrace
    STDERR.puts e.message
    raise e
  end

  #def after_all
    #ftp.quit
  #end

  def test_this_works
    assert true
  end

end
