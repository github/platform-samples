require "csv"
require "octokit"

def usage
  output=<<-EOM
  usage: ruby find_inactive_members.rb orgName YYYY-MM-DD purge(optional)"
  To run this script, please set the following environment variables:
    - GITHUB_TOKEN: A valid personal access token with Organzation admin priviliges
    - GITHUB_API_ENDPOINT: A valid GitHub/GitHub Enterprise API endpoint URL
                    (use https://api.github.com for GitHub.com auditing)
  EOM
  output
end

begin
  ACCESS_TOKEN = ENV.fetch("GITHUB_TOKEN")
  API_ENDPOINT = ENV.fetch("GITHUB_API_ENDPOINT", "https://api.github.com")
rescue KeyError
  puts usage
end

stack = Faraday::RackBuilder.new do |builder|
  builder.use Octokit::Middleware::FollowRedirects
  builder.use Octokit::Response::RaiseError
  builder.use Octokit::Response::FeedParser
  builder.response :logger
  builder.adapter Faraday.default_adapter
end

Octokit.configure do |kit|
  kit.api_endpoint = API_ENDPOINT
  kit.access_token = ACCESS_TOKEN
  kit.auto_paginate = true
  # kit.middleware = stack
end

@client = Octokit::Client.new

if ARGV.length > 3 || ARGV.length == 0
  puts usage
  exit(1)
end

if ARGV[2] == "purge"
  print "Do you really want to purge all members of #{ARGV[0]} inactive since #{ARGV[1]}? y/n: "
  response = STDIN.gets.chomp
  if response != "y"
    exit(1)
  end
end

# get all organization members and place into an array of hashes
@members = []
@client.organization_members(ARGV[0]).each do |member|
  hsh = {}
  hsh["login"] = member["login"]
  hsh["active"] = false
  @members << hsh
end

# get all repos in the organizaton and place into a hash
@repos = []
@client.organization_repositories(ARGV[0]).each do |repo|
  hsh = {}
  hsh["full_name"] = repo["full_name"]
  @repos << hsh
end

@total_repos = @repos.length
@total_members = @members.length

# print update to terminal
puts "\n"
puts "Analying activity for #{@total_members} members and #{@total_repos} repos in #{ARGV[0]}"

@repos_completed = 0

# method to switch member status to active
def make_active(login)
  hsh = @members.find { |member| member["login"] == login }
  hsh["active"] = true
end

# for each repo
@repos.each do |repo|

  print "analyzing #{repo["full_name"]}"

  # get all commits after specified date and iterate
  print "...commits"
  begin
    @client.commits_since(repo["full_name"], ARGV[1]).each do |commit|
      # if commmitter is a member of the org and not active, make active
      if t = @members.find {|member| member["login"] == commit["author"]["login"] && member["active"] == false }
        make_active(t["login"])
      end
    end
  rescue
    print "...skipping blank repo"
  end

  # get all issues after specified date and iterate
  print "...issues"
  @client.list_issues(repo["full_name"], { :since => ARGV[1] }).each do |issue|
    # if creator is a member of the org and not active, make active
    if t = @members.find {|member| member["login"] == issue["user"]["login"] && member["active"] == false }
      make_active(t["login"])
    end
  end

  # get all issue comments after specified date and iterate
  print "...issue comments"
  @client.issues_comments(repo["full_name"], { :since => ARGV[1]}).each do |comment|
    # if commenter is a member of the org and not active, make active
    if t = @members.find {|member| member["login"] == comment["user"]["login"] && member["active"] == false }
      make_active(t["login"])
    end
  end

  # get all pull request comments comments after specified date and iterate
  print "...pr comments"
  @client.pull_requests_comments(repo["full_name"], { :since => ARGV[1]}).each do |comment|
    # if commenter is a member of the org and not active, make active
    if t = @members.find {|member| member["login"] == comment["user"]["login"] && member["active"] == false }
      make_active(t["login"])
    end
  end

  # print update to terminal
  @repos_completed += 1
  print "...#{@repos_completed}/#{@total_repos} repos completed\n"

end

# open a new csv for output
CSV.open("inactive_users.csv", "wb") do |csv|
  # iterate and print inactive members
  @members.each do |member|
    if member["active"] == false
      puts "#{member["login"]} is inactive"
      csv << [member["login"]]
      if ARGV[2] == "purge"
        puts "removing #{member["login"]}"
        @client.remove_organization_member(ORGANIZATION, member["login"])
      end
    end
  end

end
