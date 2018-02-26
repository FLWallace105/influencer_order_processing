# Set up connection preferences for ActiveRecord

# Log queries to STDOUT in development
if Sinatra::Application.development?
  ActiveRecord::Base.logger = Logger.new(STDOUT)
end

db_yml_path = APP_ROOT.join('config', 'database.yml')

if db_yml_path.exist?
  ActiveRecord::Base.configurations = load_yml db_yml_path
  ActiveRecord::Base.establish_connection
elsif ENV['DATABASE_URL']
  ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
else
  raise Exception 'You must either create a /config/database.yml or set the DATABASE_URL environment variable.'
end

