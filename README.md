# Influencer Order Processing
Provides utilities to generate and track orders for influencers.

## Usage

Build the image:
```shell
git clone https://github.com/knweber/influencer_order_processing.git
cd influencer_order_processing
docker-compose build
```

Create a `.env` file in the project root. See the [Environment
section](#Environment) below.

Setup the database:
```shell
docker-compose run --rm worker rake db:create db:migrate
```

Refresh the cache:
```shell
# pull everything
docker-compose run --rm worker rake pull:all

# pull individually
docker-compose run --rm worker rake pull:orders
docker-compose run --rm worker rake pull:custom_collections
docker-compose run --rm worker rake pull:collects
docker-compose run --rm worker rake pull:products
```

Launch the application:
```shell
docker-compose up -d
```

Stop the application:
```shell
docker-compose down
```

Restart the application:
```shell
docker-compose restart
```

View logs:
```shell
docker-compose logs -f
```

### Production Notes
There is a seperate docker-compose file for production that runs services with a
configuration more suitable for a production environment. By default
`docker-compose` will run the development images. The commands above must be
altered to take advantage of this production configuration.

```shell
docker-compose -f docker-compose-prod.yml <command> [args...]
```

#### Elasticsearch

The production elasticsearch image has a couple extra requirements from the host
kernel. It requires that the `vm.max_map_count` variable be set to at least
262144. To set this on a running machine use `sudo sysctl -w vm.max_map_count=262144`.
To make this setting persist after reboot create the following file:

```shell
# /etc/sysctl.d/10-vm-max-map-count.conf

# This directive was originally added to run the elasticsearch docker image
# See here for more details:
# https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html#docker-cli-run-prod-mode
vm.max_map_count=262144
```

See [here](https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html#docker-cli-run-prod-mode)
for more info.

## Environment Variables
The project is setup to read environment variables from the `.env` file in both
normal operation using the `dotenv` gem and under docker. You must construct
your own `.env` file as appropriate for your environment.

The following environment variables are required. They have been filled in with
their default development values for running under docker.

```shell
REDIS_URL=redis://redis:6379
RACK_ENV=development
SHOPIFY_API_KEY=
SHOPIFY_SHARED_SECRET=
SHOPIFY_PASSWORD=
SHOPIFY_SHOP_NAME=ellieactive
DATABASE_URL=postgres://postgres:1ampostgres@postgres:5432/development
SENDGRID_API_KEY=
FTP_HOST=ftp
FTP_USER=ftp_user
FTP_PASSWORD=ftp_password
OUR_EMAIL=no-reply@ellie.com
AUTH_USERNAME=admin
AUTH_PASSWORD=admin_pass
AUTH_SESSION_ID=1
ELASTIC_PASSWORD=elastic_password
ELASTICSEARCH_URL=http://elastic:elastic_password@elasticsearch:9200

# development only
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
```

## Testing

Tests are run using `rake test`. To invoke tests in the docker test environment
run `docker-compose run --rm worker rake test`.

See [the testing guide](/file/TESTING.md) for more information on writing
tests.

## API Docs

API docs are created / maintained using YARD. Here are a couple very helpful
commands when developing againste this project.

Run a web server with all API docs (regenerates docs on file changes):
```shell
yard server -r
```

Documentation for project Gems

```shell
# after bundle install
yard gems

# to generate documentation when new gems are installed
yard config --gem-install-yri

# run server
yard server --gemfile
```
