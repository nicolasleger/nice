# nice

A Ruby gem for accessing and managing OpenData from Nice Côte d'Azur (NCA) metropolitan area via CKAN API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'nice'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install nice

## Configuration

Configure the gem with your CKAN instance URL and API key:

```ruby
require 'nice'

Nice.configure do |config|
  config.ckan_url = "https://opendata.nicecotedazur.org/data/"
  config.api_key = "your-api-key-here"
end
```

Alternatively, set environment variables:

```bash
export NICE_CKAN_URL="https://opendata.nicecotedazur.org/data/"
export NICE_CKAN_API_KEY="your-api-key-here"
```

## Usage

### Create a client

```ruby
client = Nice::Client.new
```

Or with direct credentials:

```ruby
client = Nice::Client.new(
  ckan_url: "https://opendata.nicecotedazur.org/data/",
  api_key: "your-api-key-here"
)
```

### List packages (datasets)

```ruby
packages = client.list_packages
puts "Found #{packages.count} packages"
```

### Search for datasets

```ruby
results = client.search_packages("transport")
puts "Found #{results['count']} matches"
```

### Get package details

```ruby
package = client.get_package("package-id")
puts package['title']
```

### List organizations

```ruby
organizations = client.list_organizations
```

### Get organization details

```ruby
org = client.get_organization("organization-id")
```

### List groups

```ruby
groups = client.list_groups
```

### Get resource details

```ruby
resource = client.get_resource("resource-id")
```

## Development

After checking out the repo, run `bundle install` to install dependencies.

### Running Tests

Run the test suite:

```bash
bundle exec rspec
```

Run tests with detailed output:

```bash
bundle exec rspec --format documentation
```

Run a specific test file:

```bash
bundle exec rspec spec/nice/client_spec.rb
```

### Linting

Check code style with RuboCop:

```bash
bundle exec rubocop
```

## Contributing

Bug reports and pull requests are welcome.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
