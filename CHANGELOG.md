# Changelog of RorVsWild

### Unreleased

* Measure render collection

## 1.8.1 (2024-10-17)

* Hide widget does not inject anything in HTML response
* Fix Set#join undefined method since it has been added from Ruby 3.0

## 1.8.0 (2024-06-14)

* Measure easily any Ruby method:

  ```ruby
  class Model
    def self.foo
      # ...
    end

    def bar
      # ...
    end

    RorVswild.measure(method(:foo))
    RorVswild.measure(instance_method(:bar))
  end
  ```

* Time garbage collector

  A section with the kind `gc` measures how long the GC ran during a request or a job.
  All GC executions are added together in a single section.
  For each section, the time spent in the GC is substracted.

  It might not be listed for all requests and jobs, since the GC is triggered when Ruby is running out of memory.
  You can force that in development by calling `GC.start`.

  From Ruby 3.1 it is enabled by default via and the agent uses `GC.total_time`.
  Before Ruby 3.1 the agent uses `GC::Profiler.total_time` and it must be enabled with `GC::Profiler.enable`.

* Store requests, jobs and errors into the local profiler

  Even after restarting the server, past requests, jobs and error are still viewable from the local profiler.
  Upto the last 100 entries are stored per type.
  They are stored into JSON files located in tmp directory.

## 1.7.1 (2024-06-03)

* Fix DelayedJob name and args for ActiveJob wrappers
* Limit server timing header to 10 entries
* Print ASCII server timing in logs
* Improve widget UI

## 1.7.0 (2024-04-22)

* Sample requests and jobs to lower our customers' bills

  These parameters should be used by large volume applications only.
  When the volume is significant, sending more does not improve precision and sending less does not decrease it.
  More precisely, for a large volume of requests but a low volume of jobs, it makes sens to sample requests only.

  ```yaml
  # config/rorvswild.yml
  production:
    api_key: API_KEY
    job_sampling_rate: 0.5 # 50% of jobs are sent
    request_sampling_rate: 0.25 # 25% of requests are sent
  ```

* Add Server-Timing headers

  Server-Timing is a HTTP header to provide metrics about backend runtimes.
  It's disabled by default, and it has to be enabled for each request.
  You will probably prefer to limit to privileged users in production to prevent from exposing sensitive data.
  Here is a good default setup, to enable server timing in all environments and only for admins in production:

  ```ruby
  class ApplicationController < ActionController::Base
    before_action :expose_server_timing_headers

    def expose_server_timing_headers
      # Assuming there are current_user and admin? methods
      RorVsWild.send_server_timing = !Rails.env.production? || current_user.try(:admin?)
    end
  end
  ```

## 1.6.5 (2024-04-18)

* Fix DelayedJob callback
* Limit exception message to 1 millions chars
* Fix issue #28 when for Rodauth authentication

## 1.6.4 (2024-01-12)

* Change default open timeout to 10 seconds
* Open files in your text editor by clicking from the local widget

  It should be set with an env variable when developers are not using the same editor.

  ```yaml
  # config/rorvswild.yml
  development:
    # VSCode: vscode://file${path}:${line}
    # Sublime: subl://${path}:${line}
    editor_url: <%= ENV.fetch("RORVSWILD_EDITOR_URL", "vscode://file${path}:${line}") %>
  ```

* Increase max command size to 5 000 characters
* Close local profiler details panel with Escape key
* Remove margins to display local profiler details panel in full screen
* Hide local profiler mini button when details panel is open
* Reduce CSS size

## 1.6.3 (2023-11-17)

* Fix not git repository stderr
* Normalize SQL queries
* Ignore errors with a rescue handler (rescue_from, retry_on and discard_on)
* Update local profiler colors
* Wait for queue to start before sending deployment information

## 1.6.2 (2023-02-23)

* Ignore jobs, requests and exceptions with regexes

## 1.6.1 (2023-02-07)

* Add generic way to provide server hostname
* Add generic way to provide deployment data
* Fix installer for Ruby 3.2 (Miha Rekar)

## 1.6.0 (2023-01-27)

* Track deployment revisions
* Update server metrics every minute
* Link requests and jobs performances to server name
* Add Rails version to environment details
* Enable server metrics monitoring by default
* Fix CPU usage report

## 1.5.17 (2022-10-25)

* Fix monitoring for Redis 5

## 1.5.16 (2022-10-03)

* Retrieve pretty dyno's hostnames for Heroku

## 1.5.15

* Monitor server metrics (must be enabled explicitly, beta feature)

## 1.5.14

* Improve list of default ignored exceptions
* Log HTTP requests host and verb only
* Log Redis commands without arguments
* Add simpler method RorVsWild.measure

## 1.5.13

* Pre-fill error context at the begining of a request or job with RorVsWild.merge_error_context(hash)

## 1.5.12

* Fix config API key

## 1.5.11

* Add option to change widget position

## 1.5.10

* Decrease log level to debug
* Improve relevant path

## 1.5.9

* Remove cwd in paths
* Add Ruby version HTTP header
* Add environment context to errors (OS, Ruby version, cwd, host and PID)

## 1.5.8

* Ensure Resque plugin is not installed twice

## 1.5.7

* Fix for Rails 4.2 where ActionController::API does not exist

## 1.5.6

* Add support for ActionController::API

## 1.5.5

* Add Rails version HTTP header
* Use HTTP persistent connections

## 1.5.4

* Replace process_action.action_controller callback since it cannot get controller instance in Rails 4

## 1.5.3

* Replace action dispatch plugin by a rack middleware

## 1.5.2

* Accept all loggers as long as they respond to info, warn and error
* Add RorVsWild.check
* Fix ensure block for old Ruby versions
* Optimize relevant path Locator
* Measure ActionDispatch

## 1.5.1

* Use Rails.logger by default

## 1.5.0

* Support Faktory jobs
