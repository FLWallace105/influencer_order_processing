require_relative '../test_helper'
require 'pry'

class InfluencerTest < Minitest::Test
  include TransactionalDB
  #self.use_transactional_tests = true

  def test_no_commas_in_any_fields
    influencer = Influencer.new(
      first_name: 'My,First,Name',
      last_name: 'last,name',
      address1: '2000 Bandini Dr, Suite 200',
      address2: 'Apt, 3',
      city: 'My,City',
      state: 'C,A',
      zip: '90201,2102',
      email: 'my,email@gmail.com',
      phone: '310,555,1234'
    )
    refute influencer.valid?
    influencer.attributes.each do |name, val|
      next if val.nil?
      refute_empty influencer.errors[name]
      assert influencer.errors[name].any?{|msg| msg =~ /comma/}
    end
  end

  def test_reindexes_on_change
    influencer = Influencer.first
    influencer.expects(:reindex_async).returns(true)
    influencer.touch
  end

  def test_valid_sizes
    test_sizes = {
      'XS' => true,
      'S' => true,
      'M' => true,
      'L' => true,
      'XL' => true,
      'xs' => false,
      's' => false,
      'm' => false,
      'l' => false,
      'xl' => false,
      'foo' => false,
      'BAR' => false,
    }
    test_sizes.each do |size, valid|
      influencer = Influencer.new(
        bra_size: size,
        top_size: size,
        bottom_size: size,
        sports_jacket_size: size,
      )
      influencer.validate
      if valid
        assert_empty influencer.errors[:bra_size]
        assert_empty influencer.errors[:top_size]
        assert_empty influencer.errors[:bottom_size]
        assert_empty influencer.errors[:sports_jacket_size]
      else
        refute_empty influencer.errors[:bra_size]
        refute_empty influencer.errors[:top_size]
        refute_empty influencer.errors[:bottom_size]
        refute_empty influencer.errors[:sports_jacket_size]
      end
    end
  end

  def test_to_csv
    filename = Influencer.to_csv
    assert_instance_of String, filename
    headers = Influencer::INFLUENCER_HEADERS
    CSV.new(File.open(filename)).each_with_index do |line, line_num|
      # assert correct headers and a couple correct fields
      next assert_equal headers, line if line_num == 0
    end
  end
  
end
