require 'spec_helper'

RSpec.describe Nice::Client do
  let(:ckan_url) { 'https://opendata.nicecotedazur.org/data/' }
  let(:api_key) { ENV.fetch('NICE_CKAN_API_KEY', 'test-api-key') }
  let(:client) { described_class.new(ckan_url: ckan_url, api_key: api_key) }

  describe '#initialize' do
    it 'raises error when URL is missing' do
      expect {
        described_class.new(ckan_url: nil, api_key: api_key)
      }.to raise_error(Nice::ConfigurationError, "CKAN URL is required")
    end
  end

  describe '#list_package_ids', :vcr do
    it 'returns array of package IDs' do
      result = client.list_package_ids
      expect(result).to be_an(Array)
    end
  end
end
