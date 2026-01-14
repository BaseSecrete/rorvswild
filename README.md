
# RoRvsWild

[![Gem Version](https://badge.fury.io/rb/rorvswild.svg)](https://badge.fury.io/rb/rorvswild)

<img align="right" width="120px" src="./images/rorvswild_logo.png">

*RoRvsWild* is a Ruby gem to monitor performances and exceptions in Ruby on Rails applications.

This gem has a double mode: **development** and **production**.  
It can be used without an account to monitor the performance of your requests in your development environment.  
It can also be used in your production and staging environments with an account on https://rorvswild.com. With such an account, you also get additional benefits, including 30-day trace, background job monitoring, exception monitoring, and notifications.

## Development mode

### Install the gem

* Add in your Gemfile `gem "rorvswild"`
* Run `bundle install` in your terminal.
* Restart your local server, and you’ll see a small button in the bottom left corner of your page.

<img width="218px" src="./images/rorvswild_local_button.png" alt="RoRvsWild Local button">

Click on the button, or navigate to http://localhost:3000/rorvswild to see the details panel:

![RoRvsWild Local](./images/rorvswild_local.png)

## Production mode

**To monitor your production or staging environment, you need an API key.**
Sign up on https://www.rorvswild.com and create an app to get one.

* Add in your Gemfile `gem "rorvswild"`
* Run `bundle install` in your terminal.
* Run `rorvswild-install API_KEY` in your terminal.
* Deploy/Restart your app.
* Make a few requests, and refresh your app page on rorvswild.com to view the dashboard.

![RoRvsWild Production](./images/rorvswild_prod.png)

## Full documentation

- [Installation](https://www.rorvswild.com/docs/get-started/installation)
- [Configuration](https://www.rorvswild.com/docs/get-started/configuration)

