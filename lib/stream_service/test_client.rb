require 'stream_service'

class StreamService::TestClient
  class << self
    def reset
      StreamService.client = new
    end
  end

  def db
    @db ||= Hash.new { |hash, key| hash[key] = [] }
  end

  def add_items(items)
    items.each do |item|
      db[item.stream_id] = db[item.stream_id] << item
    end
  end

  def remove_items(items)
    items.each do |item|
      db[item.stream_id].delete(item)
    end
  end

  def get_stream(stream_id:, limit: 10, pagination_slug: "")
    stream_id = StreamService.format_stream_id(stream_id)
    find_in_stream(db[stream_id], limit, pagination_slug)
  end

  def get_coalesced_stream(stream_ids:, limit: 10, pagination_slug: "")
    stream_ids = stream_ids.map { |id| StreamService.format_stream_id(id) }
    find_in_stream(stream_ids.flat_map {|id| db[id] }, limit, pagination_slug)
  end

  private

  def find_in_stream(items, limit, slug)
    sorted = items.sort_by(&:ts).reverse
    _ts, post_id = slug.split("A")
    if post_id
      start = sorted.index { |item| item.id == post_id.to_i }
    else
      start = 0
    end

    results = sorted.slice(start.to_i, limit.to_i)

    { pagination_slug: new_slug(results.last), stream_items: results }
  end

  # fake pagination slug follows real tsAitem format, but just uses unique post
  # id
  def new_slug(item)
    if item
      "#{item.ts.to_i}A#{item.id}"
    else
      ""
    end
  end
end
