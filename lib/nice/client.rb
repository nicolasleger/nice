require 'ckan'

module Nice
  class Client
    attr_reader :ckan_url, :api_key

    def initialize(ckan_url: nil, api_key: nil)
      @ckan_url = ckan_url || Nice.configuration&.ckan_url
      @api_key = api_key || Nice.configuration&.api_key

      validate_credentials!

      # add ending slash if missing
      fixed_ckan_url = @ckan_url.end_with?('/') ? @ckan_url : "#{@ckan_url}/"
      CKAN::API.api_url = fixed_ckan_url
      CKAN::API.api_version = "3"
      CKAN::API.api_key = @api_key
    end

    # List all package IDs (datasets)
    def list_package_ids
      CKAN::Package.find
    rescue => e
      raise APIError, "Failed to list packages: #{e.message}"
    end

    # Get package details
    def get_package(package_or_id)
      package_id = package_or_id.is_a?(CKAN::Package) ? package_or_id.id : package_or_id
      package = CKAN::Package.find(package_id)
      {
        'id' => package.id,
        'name' => package.name,
        'title' => package.title,
        'resources' => package.resources
      }
    rescue => e
      raise APIError, "Failed to get package: #{e.message}"
    end

    private

    def validate_credentials!
      raise ConfigurationError, "CKAN URL is required" if @ckan_url.nil? || @ckan_url.empty?

      # API key is not mandatory for public datasets, so we won't raise an error if it's missing.
      # However, we might check if it's provided and warn if not, depending on the use case.
      # raise ConfigurationError, "API key is required" if @api_key.nil? || @api_key.empty?
    end
  end
end
