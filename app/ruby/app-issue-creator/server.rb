require 'sinatra'
require 'jwt'
require 'json'
require 'active_support/all'
require 'octokit'

begin
  GITHUB_APP_ID = ENV.fetch("GITHUB_APP_ID")
  GITHUB_PRIVATE_KEY = ENV.fetch("GITHUB_APP_PRIVATE_KEY")
rescue KeyError
  $stderr.puts "To run this script, please set the following environment variables:"
  $stderr.puts "- GITHUB_APP_ID: GitHub App ID"
  $stderr.puts "- GITHUB_APP_PRIVATE_KEY: GitHub App Private Key"
  exit 1
end
@client = nil

# Webhook listener
post '/payload' do
  github_event = request.env['HTTP_X_GITHUB_EVENT']
  if github_event == "installation"
    parse_installation_payload(request.body.read)
  else
    puts "New event #{github_event}"
  end
end

# To authenticate as a GitHub App, generate a private key. Use this key to sign
# a JSON Web Token (JWT), and encode using the RS256 algorithm. GitHub checks 
# that the request is authenticated by verifying the token with the
# integration's stored public key. https://git.io/vQOLW
def get_jwt_token
  private_key = OpenSSL::PKey::RSA.new(GITHUB_PRIVATE_KEY)

  payload = {
    # issued at time
    iat: Time.now.to_i,
    # JWT expiration time (10 minute maximum)
    exp: 5.minutes.from_now.to_i,
    # GitHub App's identifier
    iss: GITHUB_APP_ID
  }

  JWT.encode(payload, private_key, "RS256")
end

# A GitHub App is installed by a user on one or more repositories.
# The installation ID is passed in the webhook event. This returns all 
# repositories this installation has access to.
def get_app_repositories
  json_response = @client.list_installation_repos

  repository_list = []
  if json_response.count > 0
    json_response["repositories"].each do |repo|
      repository_list.push(repo["full_name"])
    end
  else
    puts json_response
  end

  repository_list
end

# For each repository that has Issues enabled, create an issue stating that a
# GitHub App was installed
def create_issues(repositories, sender_username)
  repositories.each do |repo|
    begin
      @client.create_issue(repo, "#{sender_username} added new app!", "Added GitHub App")
    rescue
      puts "Issues is disabled for this repository"
    end
  end
end

#  When an App is added by a user, it will generate a webhook event. Parse an
# `installation` webhook event, list all repositories this App has access to,
# and create an issue.
def parse_installation_payload(json_body)
  webhook_data = JSON.parse(json_body)
  if webhook_data["action"] == "created" || webhook_data["action"] == "added"
    installation_id = webhook_data["installation"]["id"]
  
    # Get JWT for App and get access token for an installation
    jwt_client = Octokit::Client.new(:bearer_token => get_jwt_token)
    jwt_client.default_media_type = "application/vnd.github.machine-man-preview+json"
    app_token = jwt_client.create_installation_access_token(installation_id)

    # Create octokit client that has access to installation resources
    @client = Octokit::Client.new(access_token: app_token[:token] )
    @client.default_media_type = "application/vnd.github.machine-man-preview+json"

    # List all repositories this installation has access to
    repository_list = []
    if webhook_data["installation"].key?("repositories_added")
      webhook_data["installation"]["repositories_added"].each do |repo|
        repository_list.push(repo["full_name"])
      end
    else
      # Get repositories by query
      repository_list = get_app_repositories
    end
    
    # Create an issue in each repository stating an App has been given added
    create_issues(repository_list, webhook_data["sender"]["login"])
  end
end
