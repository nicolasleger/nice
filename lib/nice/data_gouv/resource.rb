module Nice
  module DataGouv
    class Resource
      attr_reader :id, :name, :description, :url, :format, :size, :created_at, :last_modified

      def initialize(attributes = {})
        @id = attributes['id']
        @name = attributes['name']
        @description = attributes['description']
        @url = attributes['url']
        @format = attributes['format']
        @size = attributes['size']
        @created_at = attributes['created']
        @last_modified = attributes['last_modified']
      end

      def to_h
        {
          'id' => @id,
          'name' => @name,
          'description' => @description,
          'url' => @url,
          'format' => @format,
          'size' => @size,
          'created_at' => @created_at,
          'last_modified' => @last_modified
        }
      end
    end
  end
end
