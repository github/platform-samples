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

    CLIENT_ID = ENV['GITHUB_CLIENT_ID']
    CLIENT_SECRET = ENV['GITHUB_CLIENT_SECRET']

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
        octokit_client = Octokit::Client.new(:login => github_user.login, :access_token => github_user.token)
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

        language_byte_count = []
        repos.each do |repo|
          repo_name = repo.name
          repo_langs = []
          begin
            repo_url = "#{github_user.login}/#{repo_name}"
            repo_langs = octokit_client.languages(repo_url)
          rescue Octokit::NotFound
            puts "Error retrieving languages for #{repo_url}"
          end
          if !repo_langs.empty?
            repo_langs.each do |lang, count|
              if !language_obj[lang]
                language_obj[lang] = count
              else
                language_obj[lang] += count
              end
            end
          end
        end

        language_obj.each do |lang, count|
          language_byte_count.push :name => "#{lang} (#{count})", :count => count
        end

        # some mandatory formatting for d3
        language_bytes = [ :name => "language_bytes", :elements => language_byte_count]

        erb :lang_freq, :locals => { :languages => languages.to_json, :language_byte_count => language_bytes.to_json}
      end
    end
  end
end
