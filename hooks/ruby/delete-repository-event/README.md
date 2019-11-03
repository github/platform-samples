# :x: Delete Repository Event

### :dart: Purpose

This Ruby server:

1. Listens for when a [repository is deleted](https://help.github.com/enterprise/user/articles/deleting-a-repository/) using the [`repository`](https://developer.github.com/enterprise/v3/activity/events/types/#repositoryevent) event and `deleted` action.

2. Creates an issue in `GITHUB_NOTIFICATION_REPOSITORY` as a notification and includes:

    - a link to restore the repository
    - the delete repository payload

### :gear: Configuration

1. See the [webhooks](https://developer.github.com/webhooks/) documentation for information on how to [create webhooks](https://developer.github.com/webhooks/creating/) and [configure your server](https://developer.github.com/webhooks/configuring/).

2. Set the following required environment variables:

    - `GITHUB_HOST` - the domain of the GitHub Enterprise instance. e.g. github.example.com
    - `GITHUB_API_TOKEN` - a [Personal Access Token](https://help.github.com/enterprise/user/articles/creating-a-personal-access-token-for-the-command-line/) that has the ability to create an issue in the notification repository
    - `GITHUB_NOTIFICATION_REPOSITORY` - the repository in which to create the notification issue. e.g. github.example.com/administrative-notifications. Should be in the form of `:owner/:repository`. 
