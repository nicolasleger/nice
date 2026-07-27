require 'httparty'
require 'json'
require 'nokogiri'

require_relative 'job_offer'

module Nice
  module Recruitment
    # Client for recrutement.nicecotedazur.org (Eqwa ATS).
    #
    # The platform exposes no public API or feed, so offers are read from the
    # server-rendered pages: the listing page carries every current offer in a
    # single response, and detail pages carry the full field set. Filtered
    # search replays the site's own form flow (CSRF-protected POST followed by
    # a session-scoped redirect).
    class Client
      include HTTParty
      base_uri 'https://recrutement.nicecotedazur.org'
      follow_redirects true
      default_timeout 30

      LISTING_PATH = '/front-jobs.html'.freeze
      DETAIL_PATH = '/front-jobs-detail.html'.freeze

      # The CSRF token must be posted back in a form field named after the
      # cookie itself (the site's csrfprotector.js overrides the field name
      # with the value of #csrfp_hidden_data_token). A wrong or missing token
      # makes the server silently ignore the filters.
      CSRF_COOKIE = '__Secure-CSRFP-Token'.freeze

      # id_identite values wired to the entity tiles by front-jobs.js.
      ENTITIES = {
        1 => "Métropole Nice Côte d'Azur",
        2 => 'CCAS de Nice',
        3 => 'Ville de Nice'
      }.freeze

      # Normalized French <dt> labels on the detail page => JobOffer attributes.
      DETAIL_LABELS = {
        'référence' => 'reference',
        'contrat' => 'contract',
        'collectivité' => 'organization',
        'direction' => 'department',
        'localisation' => 'location',
        'lieu de travail' => 'workplace',
        'filière' => 'sector',
        'domaine' => 'domain',
        'catégorie' => 'category',
        "cadre d'emploi" => 'employment_framework',
        "cadre d'emplois" => 'employment_framework',
        'date limite' => 'deadline'
      }.freeze

      # List current job offers. Without filters this is a single stateless
      # GET returning every offer. Filters accept ids or exact labels (see
      # #search_options): keywords (String), domain, function (requires
      # domain), entity, and the multi-valued contracts, sectors, categories.
      def jobs(keywords: nil, domain: nil, function: nil, contracts: [], sectors: [], categories: [], entity: nil)
        filters = {
          'keywords' => keywords,
          'domain' => domain,
          'function' => function,
          'contracts' => Array(contracts),
          'sectors' => Array(sectors),
          'categories' => Array(categories),
          'entity' => entity
        }
        return all_jobs if filters.values.all? { |v| v.nil? || (v.is_a?(Array) && v.empty?) }

        filtered_jobs(filters)
      end

      # Get a fully populated offer from its detail page.
      def job(id)
        validate_id!(id)
        response = self.class.get(DETAIL_PATH, query: { id_job: id, id_origin: 0 }, headers: headers)
        handle_response(response) { |html| parse_detail(html, id.to_i) }
      end

      # Available filter vocabularies, parsed from the listing page:
      # { domains: {id => label}, functions: {domain_id => {id => label}},
      #   contracts:, sectors:, categories:, entities: }.
      def search_options
        response = self.class.get(LISTING_PATH, headers: headers)
        handle_response(response) { |html| parse_search_options(html) }
      end

      private

      VALID_ID = /\A\d+\z/.freeze

      def validate_id!(id)
        raise ArgumentError, "Invalid job id: #{id.inspect}" unless id.to_s.match?(VALID_ID)
      end

      def headers
        { 'Accept' => 'text/html' }
      end

      def all_jobs
        response = self.class.get(LISTING_PATH, headers: headers)
        handle_response(response) { |html| parse_listing(html) }
      end

      # The site's search flow: GET the listing (session + CSRF cookies, filter
      # vocabularies), POST the form with the token echoed as a field, then GET
      # the listing again with the same session to read the filtered table.
      def filtered_jobs(filters)
        first = self.class.get(LISTING_PATH, headers: headers)
        listing_html = handle_response(first) { |html| html }
        cookies = session_cookies(first)
        token = cookies[CSRF_COOKIE]
        raise Nice::APIError, 'CSRF token cookie missing from listing response' unless token

        form = build_filter_form(filters, parse_search_options(listing_html), token)
        post = self.class.post(
          LISTING_PATH,
          body: form,
          headers: headers.merge('Cookie' => cookie_header(cookies)),
          follow_redirects: false
        )
        # A validated POST stores the filter in the session and redirects; a
        # rejected one (stripped params) renders the full list directly with 200.
        raise Nice::APIError, "Filtered search rejected (expected redirect, got #{post.code})" unless post.code == 302

        cookies.merge!(session_cookies(post))
        response = self.class.get(LISTING_PATH, headers: headers.merge('Cookie' => cookie_header(cookies)))
        handle_response(response) { |html| parse_listing(html) }
      end

      def build_filter_form(filters, options, token)
        form = {
          'filter' => 1,
          'id_identite' => filters['entity'] ? resolve_option(filters['entity'], options[:entities], 'entity') : 0,
          'id_domaine' => filters['domain'] ? resolve_option(filters['domain'], options[:domains], 'domain') : 0,
          'mots_cles' => filters['keywords'].to_s
        }

        if filters['function']
          raise ArgumentError, 'The function filter requires a domain' unless filters['domain']

          functions = options[:functions][form['id_domaine']] || {}
          form['id_fonction'] = resolve_option(filters['function'], functions, 'function')
        end

        if filters['contracts'].any?
          form['ids_contrat'] = filters['contracts'].map do |v|
            resolve_option(v, options[:contracts], 'contract')
          end
        end
        if filters['sectors'].any?
          form['ids_fp_filiere'] = filters['sectors'].map do |v|
            resolve_option(v, options[:sectors], 'sector')
          end
        end
        if filters['categories'].any?
          form['ids_fp_categorie'] = filters['categories'].map do |v|
            resolve_option(v, options[:categories], 'category')
          end
        end

        form[CSRF_COOKIE] = token
        form
      end

      # Accepts an id (Integer or numeric String) present in the map, or an
      # exact label (case-insensitive). Raises rather than letting a typo fall
      # through to an unfiltered search.
      def resolve_option(value, options_map, kind)
        if value.is_a?(Integer) || value.to_s.match?(VALID_ID)
          id = value.to_i
          return id if options_map.key?(id)
        else
          match = options_map.find { |_, label| label.casecmp?(value.to_s.strip) }
          return match.first if match
        end

        raise ArgumentError, "Unknown #{kind}: #{value.inspect} (see #search_options for valid values)"
      end

      def session_cookies(response)
        fields = response.headers.get_fields('set-cookie') || []
        fields.each_with_object({}) do |raw, acc|
          pair = raw.split(';').first
          next unless pair&.include?('=')

          name, value = pair.split('=', 2)
          acc[name.strip] = value
        end
      end

      def cookie_header(cookies)
        cookies.map { |name, value| "#{name}=#{value}" }.join('; ')
      end

      def handle_response(response)
        case response.code
        when 200
          yield ensure_utf8(response.body.to_s)
        when 404
          raise Nice::APIError, 'Resource not found'
        when 401, 403
          raise Nice::APIError, 'Authentication failed or access denied'
        else
          raise Nice::APIError, "Request failed with status #{response.code}"
        end
      end

      def ensure_utf8(html)
        return html if html.encoding == Encoding::UTF_8 && html.valid_encoding?

        html.dup.force_encoding(Encoding::UTF_8)
      end

      # Listing table columns: 0 = update date (hidden), 1 = logo, 2 = title
      # cell (link + optional "Date limite"/"réf" labels), 3 = contract type,
      # 4 = category.
      def parse_listing(html)
        doc = Nokogiri::HTML(html)
        doc.css('table.with-datatable tbody tr').filter_map do |row|
          link = row.at_css('a[href*="front-jobs-detail"]')
          next unless link

          id = link['href'].to_s[/id_job=(\d+)/, 1]
          next unless id

          cells = row.css('td')
          labels = row.css('span.label').filter_map { |span| clean_text(span.text) }

          JobOffer.new(
            'id' => id.to_i,
            'url' => job_url(id),
            'title' => clean_text(link['title']) || clean_text(link.text),
            'updated_at' => clean_text(cells[0]&.text),
            'recruitment_nature' => clean_text(cells[3]&.text),
            'category' => clean_text(cells[4]&.text),
            'deadline' => label_value(labels, /date limite/i),
            'reference' => label_value(labels, /\Ar[ée]f/i)
          )
        end
      end

      # Text after the first colon of the matching "label : value" span.
      def label_value(labels, pattern)
        labels.find { |text| text.match?(pattern) }&.sub(/\A[^:]*:\s*/, '')
      end

      def job_url(id)
        "#{self.class.base_uri}#{DETAIL_PATH}?id_job=#{id}&id_origin=0"
      end

      def parse_detail(html, id)
        doc = Nokogiri::HTML(html)
        dl = doc.at_css('dl.dl-horizontal')
        # Unknown ids are redirected to the listing (HTTP 200 once followed),
        # so "not found" means the detail structure is absent.
        raise Nice::APIError, "Job offer #{id} not found" unless dl && doc.at_css('h1')

        attributes = {
          'id' => id,
          'url' => job_url(id),
          'title' => clean_text(doc.at_css('h1').text),
          'introduction' => block_text(doc.at_css('div.job-detail-commentaire')),
          'description' => section_text(doc, /contexte du recrutement/i),
          'profile' => section_text(doc, /profil recherch/i)
        }

        dl.css('dt').each do |dt|
          key = DETAIL_LABELS[normalize_label(dt.text)]
          next unless key

          value = clean_text(dt.at_xpath('following-sibling::dd[1]')&.text)
          attributes[key] = value if value && !attributes[key]
        end

        # The dt.visible-xs deadline dd is often empty; the deadline also
        # appears as plain text elsewhere on the page.
        attributes['deadline'] ||= doc.text[/date limite\s*:?\s*(\d{1,2}-\d{1,2}-\d{4})/i, 1]

        JobOffer.new(attributes)
      end

      def normalize_label(text)
        clean_text(text)&.downcase&.tr('’', "'")&.chomp(':')&.strip
      end

      # Content between the matching <h2> and the next <h2> in the description.
      def section_text(doc, heading_pattern)
        heading = doc.css('div.job-detail-desc h2').find { |h2| h2.text.match?(heading_pattern) }
        return nil unless heading

        nodes = []
        node = heading.next
        while node && !(node.element? && node.name == 'h2')
          nodes << node
          node = node.next
        end
        block_text(Nokogiri::HTML.fragment(nodes.map(&:to_html).join))
      end

      def parse_search_options(html)
        doc = Nokogiri::HTML(html)
        {
          domains: select_options(doc, 'id_domaine'),
          functions: functions_by_domain(html),
          contracts: select_options(doc, 'ids_contrat'),
          sectors: select_options(doc, 'ids_fp_filiere'),
          categories: select_options(doc, 'ids_fp_categorie'),
          entities: ENTITIES
        }
      end

      def select_options(doc, select_id)
        doc.css("select##{select_id} option").each_with_object({}) do |option, acc|
          value = option['value'].to_s
          next if value.empty? || value == '0'

          label = clean_text(option.text)
          acc[value.to_i] = label if label
        end
      end

      # The domain => functions map is embedded as JSON in the listing page
      # (window.FrontJobsData.mapFunctionParentChildren).
      def functions_by_domain(html)
        json = html[/mapFunctionParentChildren\s*:\s*(\{.*\})\s*,\s*$/, 1]
        return {} unless json

        JSON.parse(json).each_with_object({}) do |(domain_id, functions), acc|
          acc[domain_id.to_i] = functions.each_with_object({}) do |function, map|
            map[function['id'].to_i] = function['name']
          end
        end
      rescue JSON::ParserError
        {}
      end

      # Plain text preserving block structure: <br> and block-element
      # boundaries become newlines.
      def block_text(node)
        return nil unless node

        node = node.dup
        node.css('br').each { |br| br.replace("\n") }
        node.css('p, div, li, ul, ol, h2, h3, h4, tr').each { |el| el.add_next_sibling("\n") }
        text = node.text
                   .tr("\u00A0", ' ')
                   .gsub(/[ \t]+/, ' ')
                   .gsub(/ ?\n ?/, "\n")
                   .gsub(/\n{3,}/, "\n\n")
                   .strip
        text.empty? ? nil : text
      end

      def clean_text(text)
        return nil if text.nil?

        cleaned = text.tr("\u00A0", ' ').gsub(/\s+/, ' ').strip
        cleaned.empty? ? nil : cleaned
      end
    end
  end
end
