require 'stream_service/http_error'
require 'stream_service/json_error'
require 'stream_service/item'

class StreamService::StreamResponse

  attr_reader :response

  def initialize(response: nil, items: nil, pagination_slug: nil)
    @response = response
    @items = items
    @pagination_slug = pagination_slug
  end

  def code
    @response.code
  end

  def raise_if_invalid!
    case response
    when Net::HTTPSuccess, Net::HTTPFound, Net::HTTPCreated
      self
    when Net::HTTPUnprocessableEntity
      fail StreamService::HttpError, "Invalid Stream Server request (422): #{response.body}"
    when Net::HTTPBadRequest
      fail StreamService::HttpError, "Stream Server encountered error (400): #{response.body}"
    else
      fail StreamService::HttpError, "Error accessing Stream Server (#{response.code}): #{response.body}"
    end
  end

  def pagination_slug
    @pagination_slug ||= response.header['link'][/from=(.*?)>;/, 1] || ''
  end

  def stream_items
    @items ||= Oj.load(response.body).map do |item|
      StreamService::Item.new(**item.symbolize_keys)
    end
  rescue StandardError => _e
    raise StreamService::JsonError, "Problem parsing json, status: #{response.code}, body: #{response.body}"
  end
end
