module Nice
  module DataGouv
    class Organization
      attr_reader :id, :name, :slug, :title, :description, :image_url, :created_at

      def initialize(attributes = {})
        @id = attributes['id']
        @name = attributes['name']
        @slug = attributes['slug']
        @title = attributes['title'] || attributes['display_name'] || attributes['name']
        @description = attributes['description']
        @image_url = attributes['logo'] || attributes['image_url'] || attributes['image_display_url']
        @created_at = attributes['created_at'] || attributes['created']
      end

      def to_h
        {
          'id' => @id,
          'name' => @name,
          'slug' => @slug,
          'title' => @title,
          'description' => @description,
          'image_url' => @image_url,
          'created_at' => @created_at
        }
      end
    end
  end
end
