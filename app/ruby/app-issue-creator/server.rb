require 'sinatra'
require 'jwt'
require 'rest_client'
require 'json'
require 'active_support/all'
require 'octokit'


post '/payload' do
  github_event = request.env['HTTP_X_GITHUB_EVENT']
  if github_event == "integration_installation"
    #|| github_event == "installation_repositories"
    parse_installation_payload(request.body.read)
  else
    puts "New event #{github_event}"
  end

end

def get_jwt
  path_to_pem = './platform-samples.pem'
  private_pem = File.read(path_to_pem)
  private_key = OpenSSL::PKey::RSA.new(private_pem)

  payload = {
    # issued at time
    iat: Time.now.to_i,
    # JWT expiration time (10 minute maximum)
    exp: 5.minutes.from_now.to_i,
    # Integration's GitHub identifier
    iss: 2583
  }

  JWT.encode(payload, private_key, "RS256")
end

def get_app_repositories(token)
  url = "https://api.github.com/installation/repositories"
  headers = {
    authorization: "token #{token}",
    accept: "application/vnd.github.machine-man-preview+json"
  }

  response = RestClient.get(url,headers)
  json_response = JSON.parse(response)

  repository_list = []
  if json_response["total_count"] > 0
    json_response["repositories"].each do |repo|
      repository_list.push(repo["full_name"])
    end
  end

  repository_list
end


def create_issues(access_token, repositories, sender_username)
  client = Octokit::Client.new(access_token: access_token )
  client.default_media_type = "application/vnd.github.machine-man-preview+json"

  repositories.each do |repo|
    begin
      client.create_issue(repo, "#{sender_username} created new app!", "Added GitHub App")
    rescue
      puts "no issues in this repository"
    end
  end
end


def get_app_token(access_tokens_url)
  jwt = get_jwt

  headers = {
    authorization: "Bearer #{jwt}",
    accept: "application/vnd.github.machine-man-preview+json"
  }
  response = RestClient.post(access_tokens_url,{},headers)

  app_token = JSON.parse(response)
  app_token["token"]
end


def parse_installation_payload(json_body)
  webhook_data = JSON.parse(json_body)
  if webhook_data["action"] == "created" || webhook_data["action"] == "added"
    access_tokens_url = webhook_data["installation"]["access_tokens_url"]
    # Get token for app
    app_token = get_app_token(access_tokens_url)
    
    repository_list = []
    if webhook_data["installation"].key?("repositories_added")
      webhook_data["installation"]["repositories_added"].each do |repo|
        repository_list.push(repo["full_name"])
      end
    else
      # Get repositories by query
      repository_list = get_app_repositories(app_token) 
    end
    
    create_issues(app_token, repository_list, webhook_data["sender"]["login"])
  end
end
