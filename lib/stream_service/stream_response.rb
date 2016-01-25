require 'stream_service/http_error'
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
      raise StreamService::HttpError, "Invalid Stream Server request (422): #{response.body}"
    when Net::HTTPBadRequest
      raise StreamService::HttpError, "Stream Server encountered error (400): #{response.body}"
    else
      raise StreamService::HttpError, "Error accessing Stream Server (#{response.code}): #{response.body}"
    end
  end

  def pagination_slug
    @pagination_slug ||= response.header["link"][/from=(.*?)>;/, 1] || ""
  end

  def items
    @items ||= Oj.load(response.body).map do |item|
      StreamService::Item.new(**item.symbolize_keys)
    end
  rescue StandardError => _e
    raise "Problem parsing json, status: #{response.code}, body: #{response.body}"
  end

  # Preserve old hash access
  def [](key)
    if key == :pagination_slug
      pagination_slug
    elsif key == :stream_items
      items
    else
      nil
    end
  end
end
