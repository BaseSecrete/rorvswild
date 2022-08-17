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
