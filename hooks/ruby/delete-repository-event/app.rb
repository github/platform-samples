# Hook example for notifying an administrator in a repository by creating an issue when a repository is deleted.
#
# Needs the following environment variables
#   GITHUB_HOST - the domain of the GitHub Enterprise instance. e.g. github.example.com
#   GITHUB_API_TOKEN - a Personal Access Token that has the ability to create an issue in the notification repository.
#   GITHUB_NOTIFICATION_REPOSITORY - the repository in which to create the nofication issue. e.g.
#
# Dependencies:
#   octokit   - https://github.com/octokit/octokit.rb
#   sinatrarb - http://www.sinatrarb.com/

require 'octokit'
require 'sinatra'
require 'json'

enable :logging
github_api_token               = ENV['GITHUB_API_TOKEN']
github_notification_repository = ENV['GITHUB_NOTIFICATION_REPOSITORY']
github_host_fqdn               = ENV['GITHUB_HOST']
github_api_endpoint            = "https://#{github_host_fqdn}/api/v3"

Octokit.configure do |c|
  c.api_endpoint = github_api_endpoint
  c.access_token = github_api_token
end

# Needed so that the webhook setup passes
post '/' do
  200
end

# When receiving a webhook for repository deletion (https://developer.github.com/v3/activity/events/types/#repositoryevent)
#   create an issue in the `github_notification_repository` set by environment variable
post '/delete-repository-event' do
  begin
    github_event = request.env['HTTP_X_GITHUB_EVENT']
    if github_event == "repository"
      request.body.rewind
      parsed = JSON.parse(request.body.read)
      action = parsed['action']

      if action == 'deleted'
        # create a new issue in the repository configured above
        full_name = parsed['repository']['full_name']
        purgatory_link = "https://#{github_host_fqdn}/stafftools/users/#{parsed['repository']['owner']['login']}/purgatory"
        client = Octokit::Client.new
        client.create_issue(github_notification_repository, "Repository deleted: #{full_name}", "[Restore the repository](#{purgatory_link})\n```json\n#{JSON.pretty_generate(parsed)}\n```")

        return 201,"Repository deleted: #{full_name}, notification created in #{github_notification_repository}"
      end
    end
    return 418, "No such teapot"
  rescue => e
    status 500
    "exception encountered #{e}"
  end
end
