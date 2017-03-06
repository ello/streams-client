require 'digest/sha1'
require 'active_support'
require 'active_support/core_ext/hash'

module StreamService
  TIME_STAMP_FORMAT = '%Y-%m-%dT%H:%M:%S.%N%:z'

  class Item

    attr_reader :id, :stream_id, :ts, :type

    def initialize(id:, stream_id:, ts:, type:)
      @id        = id.to_i
      @stream_id = stream_id
      @ts        = (DateTime.parse(ts, StreamService::TIME_STAMP_FORMAT) if ts.is_a? String) || ts
      @type      = type
    end

    def self.from_post(post_id:, user_id:, timestamp: DateTime.now, is_repost: false)
      self.new(
        id:        post_id,
        stream_id: StreamService.format_stream_id(user_id),
        ts:        timestamp,
        type:      is_repost ? 1:0
      )
    end

    def as_json
      {
        id:        @id.to_s,
        stream_id: @stream_id,
        ts:        @ts.strftime(StreamService::TIME_STAMP_FORMAT),
        type:      @type
      }
    end
  end
end
