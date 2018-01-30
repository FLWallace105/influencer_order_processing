class SessionNotificationsMiddleware
  def initialize(app, options={})
    @app = app
  end

  def call(env)
    session = env['rack.session']
    session[:notifications] ||= []
    @app.call(env)
  end
end
