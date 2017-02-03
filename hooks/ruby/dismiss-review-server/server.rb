require 'sinatra'
require 'json'
require 'uri'
require 'net/http'

$github_api_token = ENV['GITHUB_API_TOKEN']

post '/payload' do

  github_event = request.env['HTTP_X_GITHUB_EVENT']

  if github_event == "push"
    parsed = JSON.parse(request.body.read)

    # Get branch information
    branch_head = parsed['ref']
    branch_name = branch_head.chomp("refs/heads")
    repo_owner = parsed["repository"]["owner"]["name"]

    # Create URL to look up Pull Requests for this branch
    pulls_url = parsed['repository']['pulls_url']
    puts pulls_url_filtered = pulls_url.split('{').first + "?head=#{repo_owner}:#{branch_name}"
    url =  URI(pulls_url_filtered)
    pulls = getPulls(url)

    # parse pull requests
    if pulls.empty?
      puts "empty"
    else
      pulls.each do |pull_request|

        # Get all Reviews for a Pull Request via API
        review_url_orig = pull_request["url"] + "/reviews"
        puts review_url = URI(review_url_orig)
        reviews = getReviewList(review_url)

        reviews.each do |review|
          puts review["state"]
          review_id = review["id"]

          # Dismiss all Reviews that 'Approved' via API
          if review["state"] == "APPROVED"
            puts "INFO: found an approved"
            puts dismiss_url = URI(review_url_orig + "/#{review_id}/dismissals")
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
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Put.new(url)
  request["authorization"] = "token #{$github_api_token}"
  request["accept"] = 'application/vnd.github.black-cat-preview+json'
  request["content"] = '0'
  request["content-type"] = 'application/json'
  request["cache-control"] = 'no-cache'
  request.body = "{\n\t\"message\":\"Auto-dismissing\"\n}"

  response = http.request(request)
  if response.message != "OK"
    []
  else
    JSON.parse(response.read_body)
  end
end

# https://developer.github.com/v3/pulls/reviews/#list-reviews-on-a-pull-request
def getReviewList(url)
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Get.new(url)
  request["authorization"] = "token #{$github_api_token}"
  request["accept"] = 'application/vnd.github.black-cat-preview+json'
  request["cache-control"] = 'no-cache'

  response = http.request(request)
  if response.message != "OK"
    []
  else
    JSON.parse(response.read_body)
  end
end

def getPulls(url)
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Get.new(url)
  request["authorization"] = "token #{$github_api_token}"
  request["accept"] = 'application/vnd.github.v3+json'
  request["cache-control"] = 'no-cache'

  puts response = http.request(request)
  puts response.message
  if response.message != "OK"
    []
  else
    JSON.parse(response.read_body)
  end
end
