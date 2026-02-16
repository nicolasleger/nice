require 'httparty'

require_relative 'organization'
require_relative 'resource'
require_relative 'dataset'

module Nice
  module DataGouv
    class Client
      include HTTParty
      base_uri 'https://www.data.gouv.fr/api/1'
      follow_redirects true

      attr_reader :api_key

      # Manually curated list of organization slugs for the Nice Côte d'Azur region, sorted alphabetically.
      ORGANIZATION_SLUGS = %w[
        association-mediterraneenne-de-secourisme-du-06-1
        banque-populaire-mediterranee
        communaute-dagglomeration-cannes-lerins-1
        communaute-urbaine-nice-cote-dazur
        commune-de-cagnes-sur-mer
        commune-de-fontan
        compagnie-autobus-de-monaco
        compagnie-des-autobus-de-monaco
        conseil-departemental-du-var
        ddtm-alpes-maritimes
        departement-des-alpes-maritimes
        eau-dazur
        ecole-nationale-superieure-d-art-villa-arson-de-nice
        groupement-dassociations-de-defense-de-lenvironnement-et-des-sites-de-la-cote-dazur
        innovevents-reseau-national-dagences-evenementielles
        mairie-de-cannes
        mairie-de-grasse
        mairie-de-la-gaude
        metropole-toulon-provence-mediterranee
        nice-cote-dazur
        office-de-tourisme-metropolitain-nice-cote-dazur
        parc-national-de-port-cros
        prise-de-nice-1
        regie-ligne-dazur
        service-departemental-dincendie-et-de-secours-des-alpes-maritimes
        sictiam
        ville-dantibes
        ville-de-frejus
        ville-de-nice
      ]

      def initialize(api_key: nil)
        @api_key = api_key || ENV['DATA_GOUV_API_KEY']
      end

      # Get organization by ID or slug
      def organization(id_or_slug)
        response = self.class.get("/organizations/#{id_or_slug}", headers: headers)
        handle_response(response) do |data|
          Organization.new(data)
        end
      end

      # List organization datasets
      def organization_datasets(org_id_or_slug, page: 1, page_size: 20)
        response = self.class.get(
          "/organizations/#{org_id_or_slug}/datasets",
          query: { page: page, page_size: page_size },
          headers: headers
        )
        handle_response(response) do |data|
          (data['data'] || []).map { |d| Dataset.new(d) }
        end
      end

      # Get dataset by ID or slug
      def dataset(id_or_slug)
        response = self.class.get("/datasets/#{id_or_slug}/", headers: headers)
        handle_response(response) do |data|
          Dataset.new(data)
        end
      end

      private

      def headers
        headers = { 'Accept' => 'application/json' }
        headers['X-API-KEY'] = @api_key if @api_key
        headers
      end

      def handle_response(response)
        case response.code
        when 200
          yield response.parsed_response
        when 404
          raise Nice::APIError, "Resource not found"
        when 401, 403
          raise Nice::APIError, "Authentication failed or access denied"
        else
          raise Nice::APIError, "API request failed with status #{response.code}: #{response.body}"
        end
      rescue JSON::ParserError => e
        raise Nice::APIError, "Failed to parse API response: #{e.message}"
      end
    end
  end
end
