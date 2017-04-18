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

## Measure any code

You can measure any code like this (useful to monitor cronjobs):

```ruby
RorVsWild.measure_code("User.all.do_something_great")
```

Or like that:

```ruby
RorVsWild.measure_block("A great job name") { User.all.do_something_great }
```

Then it will appears in the jobs page.

Note that Calling `measure_code` or `measure_block` inside or a request or a job will add a section.
That is convenient to profile finely parts of your code.

## Send errors manually

When you already have a begin / rescue block, this manner suits well:

```ruby
begin
  # Your code ...
rescue => exception
  RorVsWild.record_error(exception)
end
```

If you prefer to be concise, just run the code from a block:

```ruby
RorVsWild.catch_error { 1 / 0 }  # => #<ZeroDivisionError: divided by 0>
```

Moreover, you can provide extra details when capturing errors:

```ruby
RorVsWild.record_error(exception, {something: "important"})
```

```ruby
RorVsWild.catch_error(something: "important") { 1 / 0 }
```

## Ignore exceptions

By using the ignored_exceptions parameter you can prevent RorVsWild from recording specific exceptions.

```yaml
# config/rorvswild.yml
production:
  api_key: API_KEY
  ignored_exceptions:
    - ActionController::RoutingError
    - ZeroDivisionError
```

```ruby
# config/initializers/rorvswild.rb
RorVsWild::Client.new(
  api_key: "API_KEY",
  ignored_exceptions: ["ActionController::RoutingError", "ZeroDivisionError"])
```

By default ActionController::RoutingError is ignored in order to not be flooded with 404.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/rorvswild/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
