require 'spec_helper'

RSpec.describe Nice::DataGouv::Client do # rubocop:disable Metrics/BlockLength
  let(:api_key) { ENV.fetch('DATA_GOUV_API_KEY', nil) }
  let(:client) { described_class.new(api_key: api_key) }

  let(:organization_id_or_slug) { 'nice-cote-dazur' }
  let(:dataset_id_or_slug) { 'export-quotidien-au-format-gtfs-du-reseau-de-transport-lignes-d-azur' }

  describe '#organization', :vcr do
    it 'returns an Organization object' do
      org = client.organization(organization_id_or_slug)

      expect(org).to be_a(Nice::DataGouv::Organization)
      expect(org.id).to be_a(String)
      expect(org.title).to be_a(String)
      expect(org.name).to be_a(String)
    end
  end

  describe '#organization_datasets', :vcr do
    it 'returns an array of Dataset objects' do
      datasets = client.organization_datasets(organization_id_or_slug, page: 1, page_size: 5)

      expect(datasets).to be_an(Array)
      expect(datasets.first).to be_a(Nice::DataGouv::Dataset) if datasets.any?

      if datasets.any?
        dataset = datasets.first
        expect(dataset.title).to be_a(String)
        expect(dataset.id).to be_a(String)
      end
    end
  end

  describe '#dataset', :vcr do
    it 'returns a Dataset object' do
      dataset = client.dataset(dataset_id_or_slug)

      expect(dataset).to be_a(Nice::DataGouv::Dataset)
      expect(dataset.id).to be_a(String)
      expect(dataset.title).to be_a(String)
      expect(dataset.resources).to be_an(Array)
      expect(dataset.resources.first).to be_a(Nice::DataGouv::Resource) if dataset.resources.any?
    end
  end
end
