require_relative '../test_helper'
require 'pry'

class InfluencerTest < ActiveSupport::TestCase

  def test_valid_influencer()
    puts Influencer.connection.pretty_inspect
  end

end
