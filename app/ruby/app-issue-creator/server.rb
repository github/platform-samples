require 'sinatra'
require 'jwt'
require 'json'
require 'active_support/all'
require 'octokit'

@client = nil

post '/payload' do
  github_event = request.env['HTTP_X_GITHUB_EVENT']
  if github_event == "integration_installation"
    #|| github_event == "installation_repositories"
    parse_installation_payload(request.body.read)
  else
    puts "New event #{github_event}"
  end

end

def get_jwt_token
  path_to_pem = './platform-samples-app-bot.2017-06-24.private-key.pem'
  private_pem = File.read(path_to_pem)
  private_key = OpenSSL::PKey::RSA.new(private_pem)

  payload = {
    # issued at time
    iat: Time.now.to_i,
    # JWT expiration time (10 minute maximum)
    exp: 5.minutes.from_now.to_i,
    # GitHub App's identifier
    iss: 2583
  }

  JWT.encode(payload, private_key, "RS256")
end

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


def create_issues(repositories, sender_username)
  repositories.each do |repo|
    begin
      @client.create_issue(repo, "#{sender_username} created new app!", "Added GitHub App")
    rescue
      puts "Issues is disabled for this repository"
    end
  end
end

def parse_installation_payload(json_body)
  webhook_data = JSON.parse(json_body)
  if webhook_data["action"] == "created" || webhook_data["action"] == "added"
    installation_id = webhook_data["installation"]["id"]
    # Get token for app
    puts get_jwt_token
    jwt_client = Octokit::Client.new(:bearer_token => get_jwt_token)
    jwt_client.default_media_type = "application/vnd.github.machine-man-preview+json"
    app_token = jwt_client.create_installation_access_token(installation_id)

    @client = Octokit::Client.new(access_token: app_token[:token] )
    @client.default_media_type = "application/vnd.github.machine-man-preview+json"
        
    repository_list = []
    if webhook_data["installation"].key?("repositories_added")
      webhook_data["installation"]["repositories_added"].each do |repo|
        repository_list.push(repo["full_name"])
      end
    else
      # Get repositories by query
      repository_list = get_app_repositories
    end
    
    create_issues(repository_list, webhook_data["sender"]["login"])
  end
end
