require "csv"
require "octokit"
require 'optparse'
require 'optparse/date'


class InactiveMemberSearch
  attr_accessor :organization, :members, :repositories, :date

  SCOPES=["read:org", "read:user", "repo", "user:email"]

  def initialize(options={})
    @client = options[:client]
    if options[:check]
      check_app
      check_scopes
      check_rate_limit
      exit 0
    end

    raise(OptionParser::MissingArgument) if (
      options[:organization].nil? or
      options[:date].nil?
    )

    @date = options[:date]
    @organization = options[:organization]
    @email = options[:email]

    organization_members
    organization_repositories
    member_activity
  end

  def check_app
    info "Application client/secret? #{@client.application_authenticated?}\n"
    info "Authentication Token? #{@client.token_authenticated?}\n"
  end

  def check_scopes
    info "Scopes: #{@client.scopes.join ','}\n"
  end

  def check_rate_limit
    info "Rate limit: #{client.rate_limit}\n"
  end

  def env_help
    output=<<-EOM
  Required Environment variables:
    OCTOKIT_ACCESS_TOKEN: A valid personal access token with Organzation admin priviliges
    OCTOKIT_API_ENDPOINT: A valid GitHub/GitHub Enterprise API endpoint URL (Defaults to https://api.github.com)
  EOM
    output
  end

  # helper to get an auth token for the OAuth application and a user
  def get_auth_token(login, password, otp)
    temp_client = Octokit::Client.new(login: login, password: password)
    res = temp_client.create_authorization(
      {
        :idempotent => true,
        :scopes => SCOPES,
        :headers => {'X-GitHub-OTP' => otp}
      })
    res[:token]
  end
private
  def debug(message)
    $stderr.print message
  end

  def info(message)
    $stdout.print message
  end

  def member_email(login)
    @email ? @client.user(login)[:email] : ""
  end

  def organization_members
  # get all organization members and place into an array of hashes
    info "Finding #{@organization} members "
    @members = @client.organization_members(@organization).collect do |m|
      email = 
      {
        login: m["login"],
        email: member_email(m[:login]),
        active: false
      }
    end
    info "#{@members.length} members found.\n"
  end

  def organization_repositories
    info "Gathering a list of repositories..."
    # get all repos in the organizaton and place into a hash
    @repositories = @client.organization_repositories(@organization).collect do |repo|
      repo["full_name"]
    end
    info "#{@repositories.length} repositories discovered\n"
  end

  # method to switch member status to active
  def make_active(login)
    hsh = @members.find { |member| member[:login] == login }
    hsh[:active] = true
  end

  def commit_activity(repository)
    # get all commits after specified date and iterate
    info "...commits"
    @client.commits_since(repo, @date).each do |commit|
      # if commmitter is a member of the org and not active, make active
      if t = @members.find {|member| member[:login] == commit["author"]["login"] && member[:active] == false }
        make_active(t[:login])
      end
    end
  end

  def issue_activity(repo, date=@date)
    # get all issues after specified date and iterate
    info "...issues"
    begin
      @client.list_issues(repo, { :since => date }).each do |issue|
        # if creator is a member of the org and not active, make active
        if t = @members.find {|member| member[:login] == issue["user"]["login"] && member[:active] == false }
          make_active(t[:login])
        end
      end
    rescue
      info "... no issues to check"
    end
  end

  def issue_comment_activity(repo, date=@date)
    # get all issue comments after specified date and iterate
    info "...issue comments"
    begin
      @client.issues_comments(repo, { :since => date}).each do |comment|
        # if commenter is a member of the org and not active, make active
        if t = @members.find {|member| member[:login] == comment["user"]["login"] && member[:active] == false }
          make_active(t[:login])
        end
      end
    rescue
      info "...no issues comments to check"
    end
  end

  def pr_activity(repo, date=@date)
    # get all pull request comments comments after specified date and iterate
    info "...pr comments"
    begin
      @client.pull_requests_comments(repo, { :since => date}).each do |comment|
        # if commenter is a member of the org and not active, make active
        if t = @members.find {|member| member[:login] == comment["user"]["login"] && member[:active] == false }
          make_active(t[:login])
        end
      end
    rescue
      info "...no pr comments to check"
    end
  end

 def member_activity
    @repos_completed = 0
    # print update to terminal
    info "Analyzing activity for #{@members.length} members and #{@repositories.length} repos for #{@organization}\n"

    # for each repo
    @repositories.each do |repo|
      info "rate limit remaining: #{@client.rate_limit.remaining}  "
      info "analyzing #{repo}"

      commit_activity(repo)
      issue_activity(repo)
      issue_comment_activity(repo)
      pr_activity(repo)

      # print update to terminal
      @repos_completed += 1
      info "...#{@repos_completed}/#{@repositories.length} repos completed\n"
    end

    # open a new csv for output
    CSV.open("inactive_users.csv", "wb") do |csv|
      # iterate and print inactive members
      @members.each do |member|
        if member[:active] == false
          member_detail = "#{member[:login]} <#{member[:email] unless member[:email].nil?}>"
          info "#{member_detail} is inactive\n"
          csv << [member_detail]
        end
      end
    end
  end
end

options = {}
OptionParser.new do |opts|
  opts.banner = "#{$0} - Find and output inactive members in an organization"

  opts.on('-c', '--check', "Check connectivity and scope") do |c|
    options[:check] = c
  end

  opts.on('-d', '--date MANDATORY',Date, "Date from which to start looking for activity") do |d|
    options[:date] = d.to_s
  end

  opts.on('-e', '--email', "Fetch the user email (can make the script take longer") do |e|
    options[:email] = e
  end

  opts.on('-o', '--organization MANDATORY',String, "Organization to scan for inactive users") do |o|
    options[:organization] = o
  end

  opts.on('-v', '--verbose', "More output to STDERR") do |v|
    @debug = true
    options[:verbose] = v
  end

  opts.on('-h', '--help', "Display this help") do |h|
    puts opts
    exit 0
  end
end.parse!

stack = Faraday::RackBuilder.new do |builder|
  builder.use Octokit::Middleware::FollowRedirects
  builder.use Octokit::Response::RaiseError
  builder.use Octokit::Response::FeedParser
  builder.response :logger
  builder.adapter Faraday.default_adapter
end

Octokit.configure do |kit|
  kit.auto_paginate = true
  kit.middleware = stack if @debug
end

options[:client] = Octokit::Client.new

InactiveMemberSearch.new(options)