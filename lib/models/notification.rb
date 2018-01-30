class Notification

  attr_accessor :message, :header
  attr_reader :type

  def initialize(message, type: 'info', header: nil)
    @header = header
    self.type = type
    @message = message
  end

  def type=(other)
    case other.to_s
    when 'error'
      @type = 'danger'
    else
      @type = other.to_s
    end
  end

end
