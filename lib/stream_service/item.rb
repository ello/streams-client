require 'virtus'
require 'digest/sha1'
require 'active_support'
require 'active_support/core_ext/hash'

module StreamService
  class Item
    include Virtus.model

    attribute :id, String #post id
    attribute :stream_id, String #user id
    attribute :ts, DateTime, :default => DateTime.now #ts of the post
    attribute :type, Integer, :default => 0 # 0 for post, 1 for repost

    def initialize(id:, stream_id:, ts:, type:)
      @type      = type
      @stream_id = stream_id
      @id        = id.to_i
      @ts        = (DateTime.parse(ts) if ts.is_a? String) || ts
    end

    def self.from_post(post_id:, user_id:, timestamp: DateTime.now, is_repost: false)
      self.new(
        id:        post_id,
        stream_id: user_id,
        ts:        timestamp,
        type:      is_repost ? 1:0
      )
    end

    def to_hash
      {
        id:        @id.to_s,
        stream_id: @stream_id,
        ts:        @ts.iso8601,
        type:      @type
      }
    end
  end
end
