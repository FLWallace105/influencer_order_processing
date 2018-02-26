require_relative 'test_helper'
require_relative '../lib/paginate.rb'

class PaginateTest < Minitest::Test
  def test_results
    a = [1,2,3,4,5,6,7]
    page = Paginate.new a, limit: 2
    assert_equal [1, 2], page.results
    assert_equal [3, 4], page.results(page: 2)
  end

  def test_count
    a = [1,2,3,4,5,6,7]
    assert_equal 7, Paginate.new(a, limit: 1).count
    assert_equal 1, Paginate.new(a, limit: 7).count
    assert_equal 1, Paginate.new(a, limit: 10).count
    assert_equal 4, Paginate.new(a, limit: 2).count
    assert_equal 1, Paginate.new([]).count
  end

  def test_last_page
    assert Paginate.new([]).last_page?
    refute Paginate.new([1,2], limit: 1).last_page?
    assert Paginate.new([1,2], page: 2, limit: 1).last_page?
  end

  def test_first_page
    assert Paginate.new([]).first_page?
    refute Paginate.new([1,2], page: 2, limit: 1).first_page?
  end

  def test_offset
    assert_equal 0, Paginate.new([]).offset
    assert_equal 100, Paginate.new([]).offset(page: 3)
    assert_equal 9, Paginate.new([], limit: 3).offset(page: 4)
  end

  def test_as_json
    a = [1,2,3,4,5,6,7,8,9]
    p = Paginate.new(a, limit: 3)
    assert_equal 1, p.as_json['page']
    assert_equal 3, p.as_json['page_count']
    assert_equal [1,2,3], p.as_json['integers']
  end
end
