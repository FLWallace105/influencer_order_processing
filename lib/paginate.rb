class Paginate
  include Enumerable 

  attr_reader :page_data, :limit
  attr_accessor :page

  def initialize(page_data, page: 1, limit: 50)
    @page_data = page_data
    @page = page.to_i
    @limit = limit.to_i
    @page_count = nil
  end

  def each
    (1..count).each do |page|
      yield results(page: page)
    end
  end

  # The number of pages in the page_data
  def count
    return @page_count if @page_count
    base_count = page_data.count.fdiv(limit).ceil
    # there cannot be less than 1 page
    @page_count = base_count < 1 ? 1 : base_count
  end
  alias_method :page_count, :count
  alias_method :length, :count

  # Return a typical JSON API style object
  def as_json
    class_name = page_data.class.name.tableize rescue 'data'
    {
      'page' => page,
      'page_count' => count,
      'data' => results,
    }
  end

  # TODO
  # render the pagination widget
  def render_widget(template: :paginate)
    nil
  end

  # The offset of the page given the limit
  #
  # @param page [Integer] the page to get the offset of
  # @param limit [Integer] the number of results per page
  def offset(page: self.page)
    (page - 1) * limit
  end

  # Return the page_data belonging to the page
  #
  # @param page [Integer] The page to return data for
  def results(page: self.page)
    # see if it has activerecord like methods and use those
    if page_data.respond_to?(:limit) && page_data.respond_to?(:offset)
      return page_data.limit(limit).offset(offset(page: page))
    end
    # otherwise fall back to handling like an enum
    page_data.to_enum.with_index
      .select do |_, index|
        index >= offset(page: page) && index < (offset(page: page) + limit)
      end
      .map(&:first)
  end

  # Is the page the last?
  def last_page?(page: self.page)
    page == count
  end

  # Is this the first page?
  def first_page?
    page == 1
  end
end
