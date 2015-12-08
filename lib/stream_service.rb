require 'stream_service/version'
require 'net/http'
require 'oj'

module StreamService
  class Service
    def initialize(roshi_uri)
      @roshi_uri         = roshi_uri
      Oj.default_options = { :mode => :compat }
    end

    def add_items(items)
      body = Oj.dump(items)

      begin
        response = http_client(path: "/streams", http_verb: 'put', body: body)
      rescue StandardError => e
        puts "HTTP Request failed (#{e.message})"
      end

      response
    end

    def get_stream(stream_id:, limit: 10, pagination_slug: "")
      begin
        response = http_client(path: "/stream/#{stream_id}#{query_params(limit, pagination_slug)}", http_verb: 'get')
      rescue StandardError => e
        puts "HTTP Request failed (#{e.message})"
      end

      return_items(response)
    end

    def get_coalesced_stream(stream_ids:, limit: 10, pagination_slug: "")
      body = { streams: stream_ids }.to_json

      begin
        response = http_client(path: "/streams/coalesce#{query_params(limit, pagination_slug)}", http_verb: 'post', body: body)
      rescue StandardError => e
        puts "HTTP Request failed (#{e.message})"
      end

      return_items(response)
    end

    private

    def return_items(response)
      items = Oj.load(response.body).map { |item| StreamService::Item.new(**item.symbolize_keys) }

      { pagination_slug: new_slug(response), stream_items: items }
    end

    def http_client(path:, http_verb:, body: "")
      uri     = URI(@roshi_uri + "#{path}")
      http    = Net::HTTP.new(uri.host, uri.port)
      request = create_request(http_verb).new(uri)

      request.body = body
      request.add_field "Content-Type", "text/json"

      http.request(request)
    end

    def create_request(verb)
      case verb.downcase
        when 'get'
          Net::HTTP::Get
        when 'put'
          Net::HTTP::Put
        when 'post'
          Net::HTTP::Post
      end
    end

    def new_slug(response)
      response.header["link"][/from=(.*?)>;/, 1] || ""
    end

    def query_params(limit, pagination_slug)
      query_params = "?limit=#{limit}"
      query_params += "&from=#{pagination_slug}" unless pagination_slug.empty?
      query_params
    end
  end
end
