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

### Job offers (recrutement.nicecotedazur.org)

Job offers are read from the metropolitan recruitment site (Eqwa ATS). The
platform exposes no public API or feed, so the client parses the
server-rendered pages — expect occasional breakage if the site's markup
changes.

```ruby
recruitment = Nice::Recruitment::Client.new

# All current offers (one request; summary fields)
offers = recruitment.jobs
puts "#{offers.count} offers"

# Filtered search — pass ids or exact labels, see recruitment.search_options
recruitment.jobs(keywords: "informatique")
recruitment.jobs(categories: %w[A B], sectors: ["Technique"])
recruitment.jobs(domain: "INFORMATIQUE & TIC", entity: "Ville de Nice")

# Full detail for one offer
offer = recruitment.job(offers.first.id)
offer.title        # => "Auxiliaire de Puériculture vacataire (H/F)"
offer.contract     # => "Contrat vacataire"
offer.organization # => "VILLE DE NICE"
offer.deadline     # => Date (or nil)
offer.description  # plain text
offer.profile      # plain text

# Full details for everything (one request per offer — be considerate)
detailed = recruitment.jobs.map { |o| recruitment.job(o.id) }
```

Listing offers carry summary fields (`updated_at`, `recruitment_nature`);
detail offers carry the full set (`contract`, `organization`, `department`,
`location`, `workplace`, `sector`, `domain`, `employment_framework`,
`introduction`, `description`, `profile`). Fields missing from a given
source are `nil`.

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
