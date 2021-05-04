require 'spec_helper'
require 'json'
require 'active_support/time'

describe StreamService::Item do
  it 'matches the expectations of our universe' do
    expect(true).to eq(true)
  end

  it 'can use the form post factory method' do
    t = Time.new(2012, 1, 8)
    item = StreamService::Item.from_post(post_id: 12345, user_id: "abc123", timestamp: t, is_repost: true)
    expect(item).not_to be_nil
    expect(item.type).to eq(1)
    expect(item.id).to eq(12345)

    # TODO This is going to change one way or the other.

    # expect(item.stream_id.length).to eq(40) # should be hashed
    # expect(item.stream_id).to eq(Digest::SHA1.hexdigest "abc123") # should be hashed
    expect(item.ts).to eq(t.iso8601)
  end

  it 'can read back in a single item from json' do
    json_val = '[{"id":"10","stream_id":"5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8","ts":"2015-12-01 15:17:21 -0700","type":0},
            {"id":"0","stream_id":"5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8","ts":"2015-12-08 15:17:21 -0700","type":0}]'

    items = Oj.load(json_val).map do |item|
      StreamService::Item.new(**item.symbolize_keys)
    end

    expect(items[0].is_a? StreamService::Item).to be true
    expect(items[0].ts.mday).to eq(1)
    expect(items[0].ts.month).to eq(12)
    expect(items[0].id).to eq(10)
  end

  it 'can marshall an array of items to JSON' do
    items = Array.new
    items << StreamService::Item.from_post(post_id: 12345, user_id: "abc123", timestamp: Time.now, is_repost: true)
    items << StreamService::Item.from_post(post_id: 12345, user_id: "abc123", timestamp: Time.now, is_repost: false)
    json = Oj.dump(items, mode: :compat)

    expect { JSON.parse(json) }.not_to raise_error
  end
end
