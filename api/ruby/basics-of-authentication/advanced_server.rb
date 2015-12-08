require "sinatra"
require "rest_client"
require "uri"
require "json"
require_relative "cli_helper"

include CLIHelper

# !!! DO NOT EVER USE HARD-CODED VALUES IN A REAL APP !!!
# Instead, set and test environment variables, like below
# if ENV["GITHUB_CLIENT_ID"] && ENV["GITHUB_CLIENT_SECRET"]
#  CLIENT_ID        = ENV["GITHUB_CLIENT_ID"]
#  CLIENT_SECRET    = ENV["GITHUB_CLIENT_SECRET"]
# end

CLIENT_ID       = ENV["GITHUB_CLIENT_ID"] || get_required_from_user("Client ID")
CLIENT_SECRET   = ENV["GITHUB_CLIENT_SECRET"] || get_required_from_user("Client Secret")
BASE_GITHUB_URL = ENV["GITHUB_URL"] || get_required_from_user("Base GitHub URL", :default => "https://github.com")
BASE_API_URL    = case URI.parse(BASE_GITHUB_URL).host
                  when "github.com"
                    "https://api.github.com"
                  when "github.dev"
                    "http://api.github.dev"
                  else
                    "#{BASE_GITHUB_URL}/api/v3"
                  end

puts "<--------------------------------------------------------------------->"
puts "GitHub lives here: #{BASE_GITHUB_URL}"
puts "The GitHub API lives here: #{BASE_API_URL}"
puts "<--------------------------------------------------------------------->"

use Rack::Session::Pool, :cookie_only => false

def authenticated?
  session[:access_token]
end

def authenticate!
  erb :index, :locals => {:client_id => CLIENT_ID, :base_url => BASE_GITHUB_URL}
end

get "/" do
  if !authenticated?
    authenticate!
  else
    access_token = session[:access_token]
    scopes = []

    begin
      auth_result = RestClient.get("#{BASE_API_URL}/user",
                                   {:params => {:access_token => access_token},
                                    :accept => :json})
    rescue => e
      # request didn't succeed because the token was revoked so we
      # invalidate the token stored in the session and render the
      # index page so that the user can start the OAuth flow again

      session[:access_token] = nil
      return authenticate!
    end

    # the request succeeded, so we check the list of current scopes
    if auth_result.headers.include? :x_oauth_scopes
      scopes = auth_result.headers[:x_oauth_scopes].split(", ")
    end

    auth_result = JSON.parse(auth_result)

    if scopes.include? "user:email"
      auth_result["private_emails"] =
        JSON.parse(RestClient.get("#{BASE_API_URL}/user/emails",
                       {:params => {:access_token => access_token},
                        :accept => :json}))
    end

    erb :advanced, :locals => auth_result
  end
end

get "/callback" do
  session_code = request.env["rack.request.query_hash"]["code"]

  binding.pry

  result = RestClient.post("#{BASE_GITHUB_URL}/login/oauth/access_token",
                          {:client_id => CLIENT_ID,
                           :client_secret => CLIENT_SECRET,
                           :code => session_code},
                           :accept => :json)

  session[:access_token] = JSON.parse(result)["access_token"]

  redirect "/"
end
