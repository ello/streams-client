require 'spec_helper'
require 'active_support/time'

describe StreamService do
  let(:service) { StreamService }
  let(:item1) { StreamService::Item.from_post(post_id: 12345, user_id: "abc123", timestamp: DateTime.now - 2.minutes, is_repost: true) }
  let(:item2) { StreamService::Item.from_post(post_id: 12345, user_id: "abc123", timestamp: DateTime.now, is_repost: false) }
  let!(:items) { [item1, item2] }

  it 'can send items into a stream' do
    response = service.add_items(items)

    expect(response.code).to eq "201"
  end

  it 'can get items back from a stream' do
    service.add_items(items)
    response = service.get_stream(stream_id: "abc123")

    expect(response.stream_items.length).to eq 2
    expect(response.stream_items.first.id).to eq 12345
    expect(response.stream_items.first.stream_id).to eq "test:abc123"
    expect(response.stream_items.first.type).to eq 0
    expect(response.stream_items[1].type).to eq 1
  end

  it 'can remove items from a stream' do
    service.add_items(items)
    response = service.get_stream(stream_id: "abc123")

    expect(response.stream_items.length).to eq 2

    service.remove_items(items)
    response = service.get_stream(stream_id: "abc123")

    expect(response.stream_items.length).to eq 0
  end

  it 'can grab content from multiple users' do
    items << StreamService::Item.from_post(post_id: 22, user_id: "archer", timestamp: DateTime.now - 30.minutes, is_repost: false)
    items << StreamService::Item.from_post(post_id: 33, user_id: "cyril", timestamp: DateTime.now - 29.minutes, is_repost: false)
    items << StreamService::Item.from_post(post_id: 44, user_id: "malory", timestamp: DateTime.now - 28.minutes, is_repost: false)
    items << StreamService::Item.from_post(post_id: 55, user_id: "lana", timestamp: DateTime.now - 1.hour, is_repost: false)
    items << StreamService::Item.from_post(post_id: 66, user_id: "malory", timestamp: DateTime.now - 2.hours, is_repost: false)
    service.add_items(items)
    user_ids = ["archer", "abc123", "lana", "malory"]
    response1 = service.get_coalesced_stream(stream_ids: user_ids, limit: 2)

    expect(response1.stream_items.length).to eq 2
    expect(response1.stream_items.first.id).to eq 12345
    expect(response1.stream_items[1].id).to eq 12345
    expect(response1.stream_items.first.stream_id).to eq "test:abc123"
    expect(response1.stream_items.first.type).to eq 0

    response2 = service.get_coalesced_stream(stream_ids: user_ids, limit: 3, pagination_slug: response1.pagination_slug)

    expect(response2.stream_items.length).to eq 3
    expect(response2.stream_items.first.id).to eq 44
    expect(response2.stream_items.first.stream_id).to eq "test:malory"
    expect(response2.stream_items[1].id).to eq 22
    expect(response2.stream_items[2].id).to eq 55

    response3 = service.get_coalesced_stream(stream_ids: user_ids, pagination_slug: response2.pagination_slug)

    expect(response3.stream_items.length).to eq 1
    expect(response3.stream_items.first.id).to eq 66

    response4 = service.get_coalesced_stream(stream_ids: user_ids, pagination_slug: response3.pagination_slug)

    expect(response4.stream_items.length).to eq 0
  end

  it 'can grab content from multiple users with a limit and pagination slug' do
    t = DateTime.now - 1.day
    items << StreamService::Item.from_post(post_id: 44, user_id: "asdf", timestamp: t, is_repost: false)
    items << StreamService::Item.from_post(post_id: 3, user_id: "pizza", timestamp: DateTime.now, is_repost: false)
    service.add_items(items)
    user_ids = ["asdf", "abc123"]
    response = service.get_coalesced_stream(stream_ids: user_ids, limit: 2)

    expect(response.stream_items.length).to eq 2
    expect(response.stream_items.first.id).to eq 12345
    expect(response.stream_items.first.stream_id).to eq "test:abc123"
    expect(response.stream_items.first.type).to eq 0
    expect(response.stream_items.any? { |item| item.stream_id == "test:asdf" }).to be false
    expect(response.stream_items.any? { |item| item.stream_id == "test:pizza" }).to be false

    next_response = service.get_coalesced_stream(stream_ids: user_ids, limit: 2, pagination_slug: response.pagination_slug)

    expect(next_response.stream_items.length).to eq 1
    expect(next_response.stream_items.first.id).to eq 44
    expect(next_response.stream_items.first.stream_id).to eq "test:asdf"
    expect(next_response.stream_items.first.ts.mday).to eq t.mday
    expect(next_response.stream_items.first.type).to eq 0
    expect(next_response.stream_items.any? { |item| item.stream_id == "test:abc123" }).to be false
    expect(next_response.stream_items.any? { |item| item.stream_id == "test:pizza" }).to be false
  end

  it 'can add, remove, and readd stuff' do
    service.add_items(items)
    response = service.get_stream(stream_id: 'abc123')
    expect(response.stream_items.length).to eq 2
    service.remove_items(items)
    response = service.get_stream(stream_id: 'abc123')
    expect(response.stream_items.length).to eq 0
    service.add_items(items)
    response = service.get_stream(stream_id: 'abc123')
    expect(response.stream_items.length).to eq 2
  end
end
