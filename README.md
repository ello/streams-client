<img src="http://d324imu86q1bqn.cloudfront.net/uploads/user/avatar/641/large_Ello.1000x1000.png" width="200px" height="200px" />

# Stream Service Ruby Gem

This gem provides a ruby API to the Roshi backed 
[ello/streams](https://github.com/ello/streams) service.

[![Build Status](https://travis-ci.org/ello/streams-client.svg?branch=master)](https://travis-ci.org/ello/streams-client)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'stream_service', github: 'ello/streams-client'
```

And then execute:

    $ bundle


## Usage

Add stream items to a stream:

```ruby

  item1 = StreamService::Item.from_post(
    post_id: 12345,
    user_id: "abc123",
    timestamp: DateTime.now - 2.minutes,
    is_repost: true
  )

  item2 = StreamService::Item.from_post(
    post_id: 67890,
    user_id: "def456",
    timestamp: DateTime.now - 2.minutes,
    is_repost: true
  )

  StreamService.add_items([item1, item2])

```

Retreive from stream:

```ruby

  response = StreamService.get_stream(stream_id: "abc123")
  assert response.stream_items.includes?(item1)
  assert !response.stream_items.includes?(item2)

  response = StreamService.get_coalesced_stream(stream_ids: ["abc123", "def456"])
  assert response.stream_items.includes?(item1)
  assert response.stream_items.includes?(item2)

```

Pagination, both `get_stream` and `get_coalesced_stream` behave the same:

```ruby

  10.times.do |i|
    StreamService::Item.from_post(
      post_id: i,
      user_id: "1",
      timestamp: DateTime.now - i.minutes,
      is_repost: true
    )
  end

  response = StreamService.get_stream(stream_id: "1", limit: 2)
  assert response.stream_items.size == 2
  assert response.stream_items.map(&:post_id) == [1, 2]

  response_two = StreamService.get_stream(stream_id: "1", limit: 2, pagination_slug: response.pagination_slug)
  assert response.stream_items.size == 2
  assert response.stream_items.map(&:post_id) == [3, 4]
```


## Development

After checking out the repo, run:

* Install docker & docker-compose.
* `bin/setup` to install dependencies. 
* Start the streams service: `docker-compose up -d`

Running tests requires setting the STREAM_SERVICE_URL env variable, this will
be the full url (with protocol) of your local docker host. Eg:

`export STREAM_SERVICE_URL=http://shared.local:8080`

Then, run `rake spec` to run the tests. 

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ello/stream_service.

## License
Streams is released under the [MIT License](blob/master/LICENSE.txt)

## Code of Conduct
Ello was created by idealists who believe that the essential nature of all human beings is to be kind, considerate, helpful, intelligent, responsible, and respectful of others. To that end, we will be enforcing [the Ello rules](https://ello.co/wtf/policies/rules/) within all of our open source projects. If you don’t follow the rules, you risk being ignored, banned, or reported for abuse.
