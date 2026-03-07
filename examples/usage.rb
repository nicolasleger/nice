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
