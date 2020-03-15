# CleanupVendor

[![Build Status](https://travis-ci.org/raszi/cleanup_vendor.svg?branch=master)](https://travis-ci.org/raszi/cleanup_vendor)
[![Code Climate](https://codeclimate.com/github/raszi/cleanup_vendor/badges/gpa.svg)](https://codeclimate.com/github/raszi/cleanup_vendor)
[![Test Coverage](https://codeclimate.com/github/raszi/cleanup_vendor/badges/coverage.svg)](https://codeclimate.com/github/raszi/cleanup_vendor)
[![Gem Version](https://badge.fury.io/rb/cleanup_vendor.svg)](https://badge.fury.io/rb/cleanup_vendor)

This gem was created to help minimizing the size of your docker images.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cleanup_vendor'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cleanup_vendor

## Usage

After installing all your gems in your `Dockerfile` with bundler, run the `cleanup_vendor` executable in the same `RUN` instruction to cut back the size of the docker image.

Something like:

```Dockerfile
RUN bundle install --deployment --frozen --jobs 4 --no-cache --retry 5 --without development test && \
  bundle exec cleanup_vendor --summary
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/raszi/cleanup_vendor.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
