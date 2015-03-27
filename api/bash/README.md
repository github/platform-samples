This directory contains small scripts that invoke some basic functionality of the GitHub API. Each script echos out what it will do, then performs the action.

## Running the Scripts
Each script assumes that you have set environment variable, called `GH_TOKEN`, with a valid [OAuth token](https://developer.github.com/v3/oauth/) as its value. While some of the endpoints here do not require you to authenticate, doing so will incrase your hourly rate limit from 60 to 5,000.

## API Documentation
The full documentation for the GitHub API is [available here](http://developer.github.com).
