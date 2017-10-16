require "csv"
require "octokit"
require 'optparse'
require 'optparse/date'

def env_help
  output=<<-EOM
Required Environment variables:
  GITHUB_TOKEN: A valid personal access token with Organzation admin priviliges
  GITHUB_API_ENDPOINT: A valid GitHub/GitHub Enterprise API endpoint URL (Defaults to https://api.github.com)
EOM
  output
end

begin
  ACCESS_TOKEN = ENV.fetch("GITHUB_TOKEN")
  API_ENDPOINT = ENV.fetch("GITHUB_API_ENDPOINT", "https://api.github.com")
rescue KeyError
  puts env_help 
end

options = {}
OptionParser.new do |opts|
  opts.banner = "#{$0} - Find and output inactive members in an organization"
  opts.on('-o', '--organization MANDATORY',String, "Organization to scan for inactive users") do |o|
    options[:organization] = o
  end

  opts.on('-d', '--date MANDATORY',Date, "Date from which to start looking for activity") do |d|
    options[:date] = d.to_s
  end

  opts.on('-p', '--purge', "Purge the inactive members (WARNING - DESTRUCTIVE!)") do |p|
    options[:purge] = p
  end

  opts.on('-v', '--verbose', "More output to STDERR") do |v|
    options[:verbose] = v
  end

  opts.on('-h', '--help', "Display this help") do |h|
    puts opts
    exit 0
  end
end.parse!

raise(OptionParser::MissingArgument) if (
  options[:organization].nil? and
  options[:date].nil? and
  options[:p].nil? )

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

def debug(message)
  print message
end

# get all organization members and place into an array of hashes
@members = @client.organization_members(options[:organization]).collect do |m|
  { 
    login: m["login"],
    active: false
  }
end

puts "#{@members.length} members found."

# get all repos in the organizaton and place into a hash
repos = @client.organization_repositories(options[:organization]).collect do |repo|
  repo["full_name"]
end

puts "#{repos.length} repositories found."

# method to switch member status to active
def make_active(login)
  hsh = @members.find { |member| member[:login] == login }
  hsh[:active] = true
end

# print update to terminal
debug("Analyzing activity for #{@members.length} members and #{repos.length} repos for #{options[:organization]}\n")

@repos_completed = 0

# for each repo
repos.each do |repo|
  debug("analyzing #{repo}")

  # get all commits after specified date and iterate
  debug("...commits")
  begin
    @client.commits_since(repo, options[:date]).each do |commit|
      # if commmitter is a member of the org and not active, make active
      if t = @members.find {|member| member[:login] == commit["author"]["login"] && member[:active] == false }
        make_active(t[:login])
      end
    end
  rescue
    debug("...skipping blank repo")
  end

  # get all issues after specified date and iterate
  debug("...issues")
  @client.list_issues(repo, { :since => options[:date] }).each do |issue|
    # if creator is a member of the org and not active, make active
    if t = @members.find {|member| member[:login] == issue["user"]["login"] && member[:active] == false }
      make_active(t[:login])
    end
  end

  # get all issue comments after specified date and iterate
  debug("...comments")
  @client.issues_comments(repo, { :since => options[:date]}).each do |comment|
    # if commenter is a member of the org and not active, make active
    if t = @members.find {|member| member[:login] == comment["user"]["login"] && member[:active] == false }
      make_active(t[:login])
    end
  end

  # get all pull request comments comments after specified date and iterate
  debug("...pr comments")
  @client.pull_requests_comments(repo, { :since => options[:date]}).each do |comment|
    # if commenter is a member of the org and not active, make active
    if t = @members.find {|member| member[:login] == comment["user"]["login"] && member[:active] == false }
      make_active(t[:login])
    end
  end

  # print update to terminal
  @repos_completed += 1
  debug("...#{@repos_completed}/#{repos.length} repos completed\n")
end

# open a new csv for output
CSV.open("inactive_users.csv", "wb") do |csv|
  # iterate and print inactive members
  @members.each do |member|
    if member[:active] == false
      puts "#{member[:login]} is inactive"
      csv << [member[:login]]
      if false # ARGV[2] == "purge"
        debug("removing #{member[:login]}\n")
        @client.remove_organization_member(ORGANIZATION, member[:login])
      end
    end
  end
end