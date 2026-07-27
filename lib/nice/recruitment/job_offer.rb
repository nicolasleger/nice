require 'date'

module Nice
  module Recruitment
    # A job offer from recrutement.nicecotedazur.org.
    #
    # Offers built from the listing page carry summary fields only
    # (updated_at, recruitment_nature); offers built from a detail page carry
    # the full set (contract, organization, description, ...). Fields absent
    # from the source page are nil.
    class JobOffer
      attr_reader :id, :title, :url, :reference, :category, :deadline,
                  :updated_at, :recruitment_nature, :contract, :organization,
                  :department, :location, :workplace, :sector, :domain,
                  :employment_framework, :introduction, :description, :profile

      def initialize(attributes = {})
        @id = attributes['id']
        @title = attributes['title']
        @url = attributes['url']
        @reference = attributes['reference']
        @category = attributes['category']
        @deadline = parse_date(attributes['deadline'])
        @updated_at = parse_date(attributes['updated_at'])
        @recruitment_nature = attributes['recruitment_nature']
        @contract = attributes['contract']
        @organization = attributes['organization']
        @department = attributes['department']
        @location = attributes['location']
        @workplace = attributes['workplace']
        @sector = attributes['sector']
        @domain = attributes['domain']
        @employment_framework = attributes['employment_framework']
        @introduction = attributes['introduction']
        @description = attributes['description']
        @profile = attributes['profile']
      end

      def to_h
        {
          'id' => @id,
          'title' => @title,
          'url' => @url,
          'reference' => @reference,
          'category' => @category,
          'deadline' => @deadline,
          'updated_at' => @updated_at,
          'recruitment_nature' => @recruitment_nature,
          'contract' => @contract,
          'organization' => @organization,
          'department' => @department,
          'location' => @location,
          'workplace' => @workplace,
          'sector' => @sector,
          'domain' => @domain,
          'employment_framework' => @employment_framework,
          'introduction' => @introduction,
          'description' => @description,
          'profile' => @profile
        }
      end

      private

      # Accepts a Date (pass-through), "YYYY-MM-DD" (listing update date) or
      # "DD-MM-YYYY" (deadline). Returns nil for blank or unparseable values.
      def parse_date(value)
        return value if value.is_a?(Date)

        text = value.to_s.strip
        case text
        when /\A\d{4}-\d{2}-\d{2}\z/
          Date.strptime(text, '%Y-%m-%d')
        when /\A\d{1,2}-\d{1,2}-\d{4}\z/
          Date.strptime(text, '%d-%m-%Y')
        end
      rescue ArgumentError
        nil
      end
    end
  end
end
