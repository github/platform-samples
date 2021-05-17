# Dismiss Review Server

A ruby server that listens for GitHub webhook `push` events, based on [the documentation](https://developer.github.com/webhooks/configuring/#writing-the-server), that will dismiss any `APPROVED` [Pull Request Reviews](https://help.github.com/articles/about-pull-request-reviews/).

## Configuration

Follow the [instructions](https://developer.github.com/webhooks/) of setting up a Webhook on GitHub to this server. Set the following environment variables:
- GITHUB_API_TOKEN - (Required) [OAuth token](https://developer.github.com/v3/#authentication) with write access to the repository.
- SECRET_TOKEN - (Optional) [Shared secret token](https://developer.github.com/webhooks/securing/#validating-payloads-from-github) between the GitHub Webhook and this application. Leave this unset if not using a secret token.
