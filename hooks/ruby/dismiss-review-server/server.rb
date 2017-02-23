require 'sinatra'
require 'json'
require 'rest-client'

$github_api_token = ENV['GITHUB_API_TOKEN']
$github_secret_token = ENV['SECRET_TOKEN']

post '/payload' do

  # Only validate secret token if set 
  if !$github_secret_token.nil?
    payload_body = request.body.read
    verify_signature(payload_body)
  end

  github_event = request.env['HTTP_X_GITHUB_EVENT']
  if github_event == "push"
    request.body.rewind
    parsed = JSON.parse(request.body.read)

    # Get branch information
    branch_name = parsed['ref']
    removed_slice = branch_name.slice!("refs/heads/")
    if removed_slice.nil?
      return "Not a branch. Nothing to do."
    end
    
    # Get Repository owner
    repo_owner = parsed["repository"]["owner"]["name"]

    # Create URL to look up Pull Requests for this branch
    # e.g. https://api.github.com/repos/baxterthehacker/public-repo/pulls{/number}
    pulls_url = parsed['repository']['pulls_url']
    
    # Pull off the "{/number}" and search for all Pull Requests
    # that include the branch
    pulls_url_filtered = pulls_url.split('{').first + "?head=#{repo_owner}:#{branch_name}"
    pulls = get(pulls_url_filtered)

    # parse pull requests
    if pulls.empty?
      puts "empty"
    else
      pulls.each do |pull_request|

        # Get all Reviews for a Pull Request via API
        review_url_orig = pull_request["url"] + "/reviews"
        reviews = get(review_url_orig)

        reviews.each do |review|

          # Dismiss all Reviews in 'APPROVED' state via API
          if review["state"] == "APPROVED"
            puts "INFO: found an approved Review"
            review_id = review["id"]
            dismiss_url = review_url_orig + "/#{review_id}/dismissals"
            put(dismiss_url)
          end
        end.empty? and begin
          puts "no reviews"
        end
      end
    end
  elsif github_event == "ping"
    puts github_event
  else
    puts github_event
  end
  "message received"
end

def put(url)
  jdata = JSON.generate({ message: "Auto-dismissing"})
  headers = {
    params:
      {
        access_token: $github_api_token
      },
    accept: "application/vnd.github.black-cat-preview+json"
  }
  response = RestClient.put(url, jdata, headers)
  JSON.parse(response.body)
end

def get(url)
  headers = {
    params: {
      access_token:  $github_api_token
    },
    accept: "application/vnd.github.black-cat-preview+json"
  }
  response = RestClient.get(url, headers)
  JSON.parse(response.body)
end

def verify_signature(payload_body)
  signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), ENV['SECRET_TOKEN'], payload_body)
  return halt 500, "Signatures didn't match!" unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
end
