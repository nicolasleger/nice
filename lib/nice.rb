require 'ckan'
require_relative 'nice/client'
require_relative 'nice/version'

module Nice
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class APIError < Error; end

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :ckan_url, :api_key

    def initialize
      @ckan_url = ENV['NICE_CKAN_URL'] || 'https://opendata.nicecotedazur.org/data/'

      @api_key = ENV['NICE_CKAN_API_KEY']
    end

    def validate!
      raise ConfigurationError, "CKAN URL is required" if ckan_url.nil? || ckan_url.empty?
      raise ConfigurationError, "API key is required" if api_key.nil? || api_key.empty?
    end
  end
end
