class Paginate
  include Enumerable 

  attr_reader :query, :limit
  attr_accessor :page

  def initialize(query, page: 1, limit: 50)
    @query = query
    @page = page.to_i
    @limit = limit.to_i
    @page_count = nil
  end

  def each
    pages = (1..(count + 1))
    pages.each do |page|
      yield results(page: page)
    end
  end

  def count
    return @page_count if @page_count
    @page_count = query.count.fdiv(limit).ceil
  end
  alias_method :page_count, :count
  alias_method :length, :count

  def as_json
    class_name = query.class.name.tableize rescue 'data'
    {
      'page' => page,
      'page_count' => count,
      class_name => results,
    }
  end

  # TODO
  # render the pagination widget
  def render_widget(template: :paginate)
    nil
  end

  def offset(page: nil)
    page ||= @page
    (page - 1) * limit
  end

  def results(page: nil)
    page ||= @page
    query.limit(limit).offset(offset(page: page))
  end
end
