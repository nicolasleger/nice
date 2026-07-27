#!/usr/bin/env ruby

require_relative '../lib/nice'

# Configure via environment variables (recommended — never hardcode credentials):
#   export NICE_CKAN_URL="https://opendata.nicecotedazur.org/data/"
#   export NICE_CKAN_API_KEY="your-api-key-here"
#
# The library reads these automatically. You can also override them explicitly:
Nice.configure do |config|
  config.ckan_url = ENV.fetch('NICE_CKAN_URL', 'https://opendata.nicecotedazur.org/data/')
  config.api_key  = ENV.fetch('NICE_CKAN_API_KEY', nil)
end

# Create a client
client = Nice::Client.new

# List all packages
puts "Listing packages..."
packages = client.list_packages
puts "Found #{packages.count} packages"

# Search for specific datasets
puts "\nSearching for 'transport' datasets..."
results = client.search_packages("transport")
puts "Found #{results['count']} matches"

# Get specific package details
if packages.any?
  package_id = packages.first
  puts "\nGetting details for package: #{package_id}"
  package = client.get_package(package_id)
  puts "Package name: #{package['name']}"
  puts "Package title: #{package['title']}"
end

# List organizations
puts "\nListing organizations..."
orgs = client.list_organizations
puts "Found #{orgs.count} organizations"

# Alternative: pass credentials directly (still read from env to avoid hardcoding)
# client = Nice::Client.new(
#   ckan_url: ENV.fetch('NICE_CKAN_URL'),
#   api_key:  ENV.fetch('NICE_CKAN_API_KEY', nil)
# )

# --- Job offers (recrutement.nicecotedazur.org, no credentials needed) ---
puts "\nListing job offers..."
recruitment = Nice::Recruitment::Client.new
offers = recruitment.jobs
puts "Found #{offers.count} job offers"

if offers.any?
  offer = recruitment.job(offers.first.id)
  puts "First offer: #{offer.title} (#{offer.contract}) — deadline: #{offer.deadline || 'n/a'}"
end

# Discover the available filter vocabularies (domains, functions, contracts,
# sectors, categories, entities) before building a filtered search.
puts "\nAvailable job filters..."
options = recruitment.search_options
puts "Domains: #{options[:domains].values.take(3).join(', ')}..."
puts "Contracts: #{options[:contracts].values.join(', ')}"

# Search job offers with filters. Each filter accepts an id or an exact label
# (case-insensitive); the multi-valued ones (contracts, sectors, categories)
# also take arrays. See #search_options above for valid values.
puts "\nSearching job offers with filters..."
filtered = recruitment.jobs(
  keywords: 'informatique',
  contracts: ['Titulaire / Lauréat de concours'],
  entity: 'Ville de Nice'
)
puts "Found #{filtered.count} matching offers"
filtered.first(5).each do |job|
  puts "- #{job.title} (#{job.recruitment_nature}) — #{job.category}"
end
