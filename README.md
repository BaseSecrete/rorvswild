
# RorVsWild

<img align="right" src="/images/rorvswild_logo.jpg">

*RoRvsWild* is a free ruby gem to monitor performances and quality in Ruby on Rails applications.

This gem has a double mode, development and production.
It can be used without an account to monitor your requests performances in your development environment.
It can also be used in your production and staging environments with an account on https://rorvswild.com. With such an account you also get extra benefits such as 30 day trace, background jobs monitoring, errors monitoring and notifications.


## Installation

#### Install the gem

* Add in your Gemfile `gem "rorvswild"`
* Run `bundle install` in you terminal
* Restart your local server and you’ll see a small button in the bottom left corner of your page.

![RoRvsWild Local Button](/images/rorvswild_local_button.jpg)

This is all what you need to do to monitor your local environment requests.

#### API key

**To monitor your production or staging environment, you need an API key.**
Signup on https://www.rorvswild.com and create an app to get one.

* Add in your Gemfile `gem "rorvswild"`
* Run `bundle install` in you terminal
* Run `rorvswild-setup API_KEY` in you terminal
* Deploy/Restart your app
* Make a few requests and refresh your app page on rorvswild.com to view the dashboard.

The `rorvswild-setup` command creates a `config/rorvswild.yml` file.

For those who prefer to manually use an initializer, they can do the following.

```ruby
# config/initializers/rorvswild.rb
RorVsWild.start(api_key: API_KEY)
```

You can create unlimited apps on *rorvswild.com* to monitor your different environments, or use the same key for both staging and production. If you want to add a staging server you have to edit your Gemfile.

## Development mode: *RoRvsWild Local*

![RoRvsWild Local](/images/rorvswild_local.jpg)

*RorVsWild Local* monitors the performances of requests in development environment.
It shows most of the requests performances insights *RoRvsWild.com* displays. **A big difference is everything works locally and no data is sent and recorded on our servers**. You don’t even need an account to use it.

*RoRvsWild Local* renders a small button in the bottom left corner of your page showing the runtime of the current request. If you click on it, you get all the profiled sections ordered by impact, which is depending on the sections average runtime and the calls count. As on RoRvsWild.com, the bottleneck is always on the top of the list.

Be aware that the performances on your development machine may vary from the production server. Obviously because of the different hardware and database size. Also, Rails is reloading all the code in development environment and this takes quite a lot of time.
To prevent this behaviour and better match the production, turn on cache_classes in your config/environments/development.rb:

```
Rails.application.configure do
  config.cache_classes = true
end
```

## Production mode: *RoRvsWild.com*

![RoRvsWild.com](/images/rorvswild_prod.jpg)

*RoRvsWild.com* makes it easy to monitor requests, background jobs and errors in your production and staging environment.
It also comes with some extra options listed below.

#### Measure any code

You can measure any code like this (useful to monitor cronjobs):

```ruby
RorVsWild.measure_code("User.all.do_something_great")
```

Or like that:

```ruby
RorVsWild.measure_block("A great job name") { User.all.do_something_great }
```

Then it will appear in the jobs page.

Note that Calling `measure_code` or `measure_block` inside or a request or a job will add a section.
That is convenient to profile finely parts of your code.

#### Send errors manually

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

#### Ignore exceptions

By using the ignored_exceptions parameter you can prevent *RoRvsWild* from recording specific exceptions.

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
RorVsWild.start(
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
