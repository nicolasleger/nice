require_relative 'organization'
require_relative 'resource'

module Nice
  module DataGouv
    class Dataset
      attr_reader :id, :name, :title, :notes, :organization, :resources, :tags, :created_at, :metadata_modified

      def initialize(attributes = {})
        @id = attributes['id']
        @name = attributes['name']
        @title = attributes['title']
        @notes = attributes['notes']
        @created_at = attributes['metadata_created']
        @metadata_modified = attributes['metadata_modified']
        @tags = (attributes['tags'] || []).map { |t| t.is_a?(Hash) ? t['name'] : t }

        @organization = if attributes['organization']
                          Organization.new(attributes['organization'])
                        end

        @resources = (attributes['resources'] || []).map do |resource_data|
          Resource.new(resource_data)
        end
      end

      def to_h
        {
          'id' => @id,
          'name' => @name,
          'title' => @title,
          'notes' => @notes,
          'organization' => @organization&.to_h,
          'resources' => @resources.map(&:to_h),
          'tags' => @tags,
          'created_at' => @created_at,
          'metadata_modified' => @metadata_modified
        }
      end
    end
  end
end
