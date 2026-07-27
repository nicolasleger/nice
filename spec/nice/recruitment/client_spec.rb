require 'spec_helper'

RSpec.describe Nice::Recruitment::Client do # rubocop:disable Metrics/BlockLength
  let(:client) { described_class.new }

  # A real offer id, frozen in the cassettes. Changing it re-records live.
  let(:job_id) { 2634 }

  describe '#jobs', :vcr do
    it 'returns an array of JobOffer objects from the listing' do
      offers = client.jobs

      expect(offers).to be_an(Array)
      expect(offers).not_to be_empty
      expect(offers.map(&:id).uniq.length).to eq(offers.length)

      offer = offers.first
      expect(offer).to be_a(Nice::Recruitment::JobOffer)
      expect(offer.id).to be_a(Integer)
      expect(offer.title).to be_a(String)
      expect(offer.url).to include('front-jobs-detail.html?id_job=')
      expect(offer.updated_at).to be_a(Date)
      # Detail-only fields are not present on listing offers
      expect(offer.description).to be_nil
      expect(offer.contract).to be_nil
    end

    it 'returns a filtered subset for a keyword search' do
      all_offers = client.jobs
      offers = client.jobs(keywords: 'puériculture')

      expect(offers).not_to be_empty
      expect(offers.length).to be < all_offers.length
      expect(offers).to all(be_a(Nice::Recruitment::JobOffer))
    end

    it 'filters by category label' do
      all_offers = client.jobs
      offers = client.jobs(categories: ['A'])

      expect(offers).not_to be_empty
      expect(offers.length).to be < all_offers.length
    end

    it 'raises ArgumentError for an unknown filter value' do
      expect { client.jobs(categories: ['Z']) }.to raise_error(ArgumentError, /Unknown category/)
    end
  end

  describe '#job' do
    it 'returns a fully populated JobOffer', :vcr do
      offer = client.job(job_id)

      expect(offer).to be_a(Nice::Recruitment::JobOffer)
      expect(offer.id).to eq(job_id)
      expect(offer.title).to be_a(String)
      expect(offer.reference).to be_a(String)
      expect(offer.contract).to be_a(String)
      expect(offer.organization).to be_a(String)
      expect(offer.deadline).to be_a(Date)
      expect(offer.description).to be_a(String)
      expect(offer.profile).to be_a(String)
      expect(offer.to_h).to include('id' => job_id, 'title' => offer.title)
    end

    it 'raises Nice::APIError for an unknown id', :vcr do
      expect { client.job(999_999_999) }.to raise_error(Nice::APIError, /not found/i)
    end

    it 'raises ArgumentError for a non-numeric id' do
      expect { client.job('abc') }.to raise_error(ArgumentError)
    end
  end

  describe '#search_options', :vcr do
    it 'returns the filter vocabularies parsed from the listing page' do
      options = client.search_options

      expect(options[:domains]).to be_a(Hash)
      expect(options[:domains]).not_to be_empty
      expect(options[:functions]).to be_a(Hash)
      expect(options[:functions]).not_to be_empty
      expect(options[:contracts]).not_to be_empty
      expect(options[:sectors]).not_to be_empty
      expect(options[:categories].values).to contain_exactly('A', 'B', 'C')
      expect(options[:entities].values).to include('Ville de Nice')
    end
  end
end
