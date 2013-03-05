require 'sinatra/auth/github'
require 'rest_client'

module Example
  class MyBasicApp < Sinatra::Base
    # !!! DO NOT EVER USE HARD-CODED VALUES IN A REAL APP !!!
    # Instead, set and test environment variables, like below
    # if ENV['GITHUB_CLIENT_ID'] && ENV['GITHUB_CLIENT_SECRET']
    #  CLIENT_ID        = ENV['GITHUB_CLIENT_ID']
    #  CLIENT_SECRET    = ENV['GITHUB_CLIENT_SECRET']
    # end

    CLIENT_ID = ENV['GH_BASIC_CLIENT_ID']
    CLIENT_SECRET = ENV['GH_BASIC_SECRET_ID']

    enable :sessions

    set :github_options, {
      :scopes    => "user",
      :secret    => CLIENT_SECRET,
      :client_id => CLIENT_ID,
      :callback_url => "/callback"
    }

    register Sinatra::Auth::Github

    get '/' do
      if !authenticated?
        authenticate!
      else
        access_token = github_user["token"]
        auth_result = RestClient.get("https://api.github.com/user", {:params => {:access_token => access_token, :accept => :json}, 
                                                                                  :accept => :json})

        auth_result = JSON.parse(auth_result)

        erb :advanced, :locals => {:login => auth_result["login"],
                                   :hire_status => auth_result["hireable"] ? "hireable" : "not hireable"}
      end
    end

    get '/callback' do
      if authenticated?
        redirect "/"
      else
        authenticate!
      end
    end
  end
end