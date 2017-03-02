# RorVsWild

Ruby on Rails app monitoring: performances & quality insights for rails developers.

## Installation

First you need an API key. Signup here https://www.rorvswild.com to get one and a 14 day free trial.

1. Add in your Gemfile `gem "rorvswild"`
2. Run `bundle install`
3. Run `rorvswild-setup API_KEY`
4. Restart / deploy your app !

The `rorvswild-setup` create a `config/rorvswild.yml` file.
For those who prefer to manually use an initializer, they can do the following.

```ruby
# config/initializers/rorvswild.rb
RorVsWild.start(api_key: API_KEY)
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/rorvswild/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
