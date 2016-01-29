require 'stream_service/version'
require 'stream_service/stream_response'
require 'net/http'
require 'oj'
require 'forwardable'

module StreamService
  extend SingleForwardable
  STREAM_PREFIX = ENV['STREAM_SERVICE_PREFIX'] || nil
  STREAM_ENV = ENV['RAILS_ENV'] || 'development'

  class << self
    def client(service_url = ENV['STREAM_SERVICE_URL'])
      @client ||= Client.new(service_url)
    end

    def client=(client)
      @client = client
    end

    def format_stream_id(id)
      [STREAM_ENV, STREAM_PREFIX, id].compact.join(':')
    end
  end

  def_delegators :client, :add_items, :remove_items, :get_stream, :get_coalesced_stream

  class Client
    def initialize(service_uri)
      @service_uri       = service_uri
      Oj.default_options = { mode: :compat }
    end

    def add_items(items)
      body = Oj.dump(items)

      http_client(path: "/streams", http_verb: 'put', body: body)
    end

    def remove_items(items)
      body = Oj.dump(items)

      http_client(path: "/streams", http_verb: 'delete', body: body)
    end

    def get_stream(stream_id:, limit: 10, pagination_slug: "")
      stream_id = StreamService.format_stream_id(stream_id)

      http_client(path: "/stream/#{stream_id}#{query_params(limit, pagination_slug)}", http_verb: 'get')
    end

    def get_coalesced_stream(stream_ids:, limit: 10, pagination_slug: "")
      stream_ids = stream_ids.map { |id| StreamService.format_stream_id(id) }
      body = { streams: stream_ids }.to_json

      http_client(path: "/streams/coalesce#{query_params(limit, pagination_slug)}", http_verb: 'post', body: body)
    end

    private

    def http_client(path:, http_verb:, body: "")
      uri     = URI(@service_uri + "#{path}")
      http    = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      request = create_request(http_verb).new(uri)
      if uri.user && uri.password
        request.basic_auth uri.user, uri.password
      end

      request.body = body
      request.add_field "Content-Type", "text/json"

      response = StreamService::StreamResponse.new(response: http.request(request))
      response.raise_if_invalid!
    end

    def create_request(verb)
      case verb.downcase
        when 'get'
          Net::HTTP::Get
        when 'put'
          Net::HTTP::Put
        when 'post'
          Net::HTTP::Post
        when 'delete'
          Net::HTTP::Delete
      end
    end

    def query_params(limit, pagination_slug)
      query_params = "?limit=#{limit}"
      query_params += "&from=#{pagination_slug}" unless pagination_slug.empty?
      query_params
    end
  end
end
