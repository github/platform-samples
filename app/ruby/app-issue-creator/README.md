# app-issue-creator

This is the sample project that walks through creating a GitHub App and configuring a server to listen to [`installation` events](https://developer.github.com/v3/activity/events/types/#installationevent). When an App is added to an account, it will create an issue in each repository with a message, "added new app!".

## Requirements

* Ruby installed
* [Bundler](http://bundler.io/) installed
* [ngrok](https://ngrok.com/) or [localtunnel](https://localtunnel.github.io/www/) exposing port `4567` to allow GitHub to access your server

## Set up a GitHub App

* [Set up and register GitHub App](https://developer.github.com/apps/building-integrations/setting-up-and-registering-github-apps/)
* [Enable `issue` write permissions](https://developer.github.com/v3/apps/permissions/#permission-on-issues)
* If not running on a public-facing IP, use ngrok to generate a URL as [documented here](https://developer.github.com/v3/guides/building-a-ci-server/#writing-your-server)

## Install and Run project

Install the required Ruby Gems by entering `bundle install` on the command line. 

Set environment variables `GITHUB_APP_ID` and `GITHUB_APP_PRIVATE_KEY`. For example, run the following to store the private key to an environment variable: `export GITHUB_APP_PRIVATE_KEY="$(less private-key.pem)"`

To start the server, type `ruby server.rb` on the command line.

The [sinatra server](http://www.sinatrarb.com/) will be running at `localhost:4567`.

[basics of auth]: http://developer.github.com/guides/basics-of-authentication/
