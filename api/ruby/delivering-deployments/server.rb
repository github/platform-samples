require 'sinatra/base'
require 'json'
require 'octokit'

class DeploymentTutorial < Sinatra::Base

  # !!! DO NOT EVER USE HARD-CODED VALUES IN A REAL APP !!!
  # Instead, set and test environment variables, like below
  ACCESS_TOKEN = ENV['MY_PERSONAL_TOKEN']

  before do
    @client ||= Octokit::Client.new(:access_token => ACCESS_TOKEN)
  end

  post '/event_handler' do
    @payload = JSON.parse(params[:payload])

    case request.env['HTTP_X_GITHUB_EVENT']
    when "pull_request"
      if @payload["action"] == "closed" && @payload["pull_request"]["merged"]
        start_deployment(@payload["pull_request"])
      end
    when "deployment"
      process_deployment
    when "deployment_status"
      update_deployment_status
    end
  end

  helpers do
    def start_deployment(pull_request)
      user = pull_request['user']['login']
      payload = JSON.generate(:environment => 'production', :deploy_user => user)
      @client.create_deployment(pull_request['head']['repo']['full_name'], pull_request['head']['sha'], {:payload => payload, :description => "Deploying my sweet branch"})
    end

    def process_deployment
      payload = JSON.parse(@payload['payload'])
      # you can send this information to your chat room, monitor, pager, e.t.c.
      puts "Processing '#{@payload['description']}' for #{payload['deploy_user']} to #{payload['environment']}"
      sleep 2 # simulate work
      @client.create_deployment_status("repos/#{@payload['repository']['full_name']}/deployments/#{@payload['id']}", 'pending')
      sleep 2 # simulate work
      @client.create_deployment_status("repos/#{@payload['repository']['full_name']}/deployments/#{@payload['id']}", 'success')
    end

    def update_deployment_status
      puts "Deployment status for #{@payload['id']} is #{@payload['state']}"
    end
  end
end
