# Changelog of RorVsWild

## Unreleased

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
