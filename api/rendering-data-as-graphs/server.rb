require 'sinatra/auth/github'
require 'octokit'

module Example
  class MyGraphApp < Sinatra::Base
    # !!! DO NOT EVER USE HARD-CODED VALUES IN A REAL APP !!!
    # Instead, set and test environment variables, like below
    # if ENV['GITHUB_CLIENT_ID'] && ENV['GITHUB_CLIENT_SECRET']
    #  CLIENT_ID        = ENV['GITHUB_CLIENT_ID']
    #  CLIENT_SECRET    = ENV['GITHUB_CLIENT_SECRET']
    # end

    CLIENT_ID = ENV['GH_GRAPH_CLIENT_ID']
    CLIENT_SECRET = ENV['GH_GRAPH_SECRET_ID']

    enable :sessions

    set :github_options, {
      :scopes    => "repo",
      :secret    => CLIENT_SECRET,
      :client_id => CLIENT_ID,
      :callback_url => "/"
    }

    register Sinatra::Auth::Github

    get '/' do
      if !authenticated?
        authenticate!
      else
        octokit_client = Octokit::Client.new(:login => github_user.login, :oauth_token => github_user.token)
        repos = octokit_client.repositories
        language_obj = {}
        repos.each do |repo|
          # sometimes language can be nil 
          if repo.language
            if !language_obj[repo.language]
              language_obj[repo.language] = 1
            else
              language_obj[repo.language] += 1
            end
          end
        end

        languages = []
        language_obj.each do |lang, count|
          languages.push :language => lang, :count => count
        end
        
        erb :lang_freq, :locals => { :languages => languages.to_json}
      end
    end
  end
end