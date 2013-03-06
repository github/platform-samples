require 'sinatra'
require 'rest_client'
require 'json'

# !!! DO NOT EVER USE HARD-CODED VALUES IN A REAL APP !!!
# Instead, set and test environment variables, like below
# if ENV['GITHUB_CLIENT_ID'] && ENV['GITHUB_CLIENT_SECRET']
#  CLIENT_ID        = ENV['GITHUB_CLIENT_ID']
#  CLIENT_SECRET    = ENV['GITHUB_CLIENT_SECRET']
# end
CLIENT_ID = ENV['GH_BASIC_CLIENT_ID']
CLIENT_SECRET = ENV['GH_BASIC_SECRET_ID']

get '/' do
  erb :index, :locals => {:client_id => CLIENT_ID}
end

get '/callback' do
  # get temporary GitHub code...
  session_code = request.env['rack.request.query_hash']["code"]
  # ... and POST it back to GitHub
  result = RestClient.post("https://github.com/login/oauth/access_token",
                          {:client_id => CLIENT_ID,
                           :client_secret => CLIENT_SECRET,
                           :code => session_code},
                           :accept => :json)
  access_token = JSON.parse(result)["access_token"]

  auth_result = RestClient.get("https://api.github.com/user", {:params => {:access_token => access_token, :accept => :json}, 
                                                                          :accept => :json})

  auth_result = JSON.parse(auth_result)

  erb :basic, :locals => {:login => auth_result["login"],
                          :hire_status => auth_result["hireable"] ? "hireable" : "not hireable"
                         }
end