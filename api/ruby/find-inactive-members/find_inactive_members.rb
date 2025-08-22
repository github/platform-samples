require "csv"
require "octokit"
require 'optparse'
require 'optparse/date'

# Custom Faraday middleware for API request throttling
class ThrottleMiddleware < Faraday::Middleware
  # Throttle to 5000 requests per hour (approximately 1.39 requests per second)
  MAX_REQUESTS_PER_HOUR = 5000
  MIN_DELAY_SECONDS = 3600.0 / MAX_REQUESTS_PER_HOUR  # 0.72 seconds

  def initialize(app, options = {})
    super(app)
    @request_count = 0
    @hour_start_time = Time.now
    @last_request_time = Time.now
    @mutex = Mutex.new
    @debug_enabled = !ENV['THROTTLE_DEBUG'].nil? && !ENV['THROTTLE_DEBUG'].empty?
    @github_rate_limit_remaining = nil
    @github_rate_limit_reset = nil
  end

  def call(env)
    @mutex.synchronize do
      throttle_request
      log_throttle_status
    end
    
    response = @app.call(env)
    
    # Update GitHub rate limit info from response headers
    @mutex.synchronize do
      update_github_rate_limit(response)
    end
    
    response
  end

  private

  def update_github_rate_limit(response)
    if response.headers['x-ratelimit-remaining']
      @github_rate_limit_remaining = response.headers['x-ratelimit-remaining'].to_i
      @github_rate_limit_reset = response.headers['x-ratelimit-reset'].to_i if response.headers['x-ratelimit-reset']
    end
  end

  def calculate_dynamic_delay
    return MIN_DELAY_SECONDS unless @github_rate_limit_remaining && @github_rate_limit_reset
    
    # Calculate time until rate limit resets
    current_time = Time.now.to_i
    time_until_reset = [@github_rate_limit_reset - current_time, 1].max
    
    # Calculate required delay to not exceed remaining requests
    if @github_rate_limit_remaining > 0
      required_delay = time_until_reset.to_f / @github_rate_limit_remaining
      # Use the more conservative delay (either our standard delay or the calculated one)
      [MIN_DELAY_SECONDS, required_delay].max
    else
      # No requests remaining, wait until reset
      time_until_reset
    end
  end

  def throttle_request
    current_time = Time.now
    
    # Reset counter if we've moved to a new hour (sliding window)
    if current_time - @hour_start_time >= 3600
      @request_count = 0
      @hour_start_time = current_time
      @last_request_time = current_time
    end
    
    # Use dynamic delay based on actual GitHub rate limit if available
    required_delay = @github_rate_limit_remaining ? calculate_dynamic_delay : MIN_DELAY_SECONDS
    
    # Ensure minimum delay between requests
    time_since_last = current_time - @last_request_time
    if time_since_last < required_delay
      sleep_time = required_delay - time_since_last
      if sleep_time > 0
        #delay_reason = @github_rate_limit_remaining ? "dynamic" : "standard"
        #$stderr.print "Throttling: waiting #{sleep_time.round(2)}s (#{delay_reason} delay)\n"
        sleep(sleep_time)
      end
    end
    
    @request_count += 1
    @last_request_time = Time.now
    
    # Log warning if we're approaching the limit  
    if @request_count % 1000 == 0
      elapsed_hour = @last_request_time - @hour_start_time
      current_rate = elapsed_hour > 0 ? (@request_count / elapsed_hour * 3600).round(1) : 0
      github_info = @github_rate_limit_remaining ? " GitHub: #{@github_rate_limit_remaining} remaining" : ""
      $stderr.print "Throttling status: #{@request_count} requests in #{elapsed_hour.round(1)}s (#{current_rate}/hour rate)#{github_info}\n"
    end
  end

  def log_throttle_status
    # This method can be called for detailed debugging if needed
    return unless @debug_enabled
    
    elapsed_hour = Time.now - @hour_start_time
    rate_per_hour = elapsed_hour > 0 ? (@request_count / elapsed_hour * 3600).round(1) : 0
    $stderr.print "Throttle debug: #{@request_count} requests in last #{elapsed_hour.round(1)}s (#{rate_per_hour}/hour rate)\n"
  end
end

class InactiveMemberSearch
  attr_accessor :organization, :members, :repositories, :date, :unrecognized_authors

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
    @unrecognized_authors = []

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
    rate_limit = @client.rate_limit
    info "Rate limit: #{rate_limit.remaining}/#{rate_limit.limit}\n"
    info "Rate limit resets at: #{rate_limit.resets_at}\n"
    info "Throttling: Limited to #{ThrottleMiddleware::MAX_REQUESTS_PER_HOUR} requests/hour (#{ThrottleMiddleware::MIN_DELAY_SECONDS.round(2)}s min delay)\n"
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

  def add_unrecognized_author(author)
    @unrecognized_authors << author
  end

  # method to switch member status to active
  def make_active(login)
    hsh = @members.find { |member| member[:login] == login }
    hsh[:active] = true
  end

  def commit_activity(repo)
    # get all commits after specified date and iterate
    info "...commits"
    begin
      @client.commits_since(repo, @date).each do |commit|
        # if commmitter is a member of the org and not active, make active
        if commit["author"].nil?
          add_unrecognized_author(commit[:commit][:author])
          next
        end
        if t = @members.find {|member| member[:login] == commit["author"]["login"] && member[:active] == false }
          make_active(t[:login])
        end
      end
    rescue Octokit::Conflict
      info "...no commits"
    rescue Octokit::NotFound
      #API responds with a 404 (instead of an empty set) when the `commits_since` range is out of bounds of commits.
      info "...no commits"
    end
  end

  def issue_activity(repo, date=@date)
    # get all issues after specified date and iterate
    info "...Issues"
    begin
      @client.list_issues(repo, { :since => date }).each do |issue|
        # if there's no user (ghost user?) then skip this   // THIS NEEDS BETTER VALIDATION
        if issue["user"].nil?
          next
        end
        # if creator is a member of the org and not active, make active
        if t = @members.find {|member| member[:login] == issue["user"]["login"] && member[:active] == false }
          make_active(t[:login])
        end
      end
    rescue Octokit::NotFound
      #API responds with a 404 (instead of an empty set) when repo is a private fork for security advisories
      info "...no access to issues in this repo ..."
    end
  end

  def issue_comment_activity(repo, date=@date)
    # get all issue comments after specified date and iterate
    info "...Issue comments"
    begin
      @client.issues_comments(repo, { :since => date }).each do |comment|
        # if there's no user (ghost user?) then skip this   // THIS NEEDS BETTER VALIDATION
        if comment["user"].nil?
          next
        end
        # if commenter is a member of the org and not active, make active
        if t = @members.find {|member| member[:login] == comment["user"]["login"] && member[:active] == false }
          make_active(t[:login])
        end
      end
    rescue Octokit::NotFound
      #API responds with a 404 (instead of an empty set) when repo is a private fork for security advisories
      info "...no access to issue comments in this repo ..."
    end
  end

  def pr_activity(repo, date=@date)
    # get all pull request comments comments after specified date and iterate
    info "...Pull Request comments"
    @client.pull_requests_comments(repo, { :since => date }).each do |comment|
      # if there's no user (ghost user?) then skip this   // THIS NEEDS BETTER VALIDATION
      if comment["user"].nil?
        next
      end
      # if commenter is a member of the org and not active, make active
      if t = @members.find {|member| member[:login] == comment["user"]["login"] && member[:active] == false }
        make_active(t[:login])
      end
    end
  end

 def member_activity
    @repos_completed = 0
    # print update to terminal
    info "Analyzing activity for #{@members.length} members and #{@repositories.length} repos for #{@organization}\n"

    # for each repo
    @repositories.each do |repo|
      # Show rate limit from last response headers (more efficient than API call)
      if @client.last_response
        remaining = @client.last_response.headers['x-ratelimit-remaining']
        limit = @client.last_response.headers['x-ratelimit-limit']
        if remaining && limit
          reset_time = @client.last_response.headers['x-ratelimit-reset']
          if reset_time
            minutes_until_reset = [(reset_time.to_i - Time.now.to_i) / 60.0, 0].max.round(1)
            reset_info = " (resets in #{minutes_until_reset}min)"
          else
            reset_info = ""
          end
          info "#{remaining} requests remaining#{reset_info}  "
        end
      end
      
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
      csv << ["login", "email"]
      # iterate and print inactive members
      @members.each do |member|
        if member[:active] == false
          member_detail = []
          member_detail << member[:login]
          member_detail << member[:email] unless member[:email].nil?
          info "#{member_detail} is inactive\n"
          csv << member_detail
        end
      end
    end

    CSV.open("unrecognized_authors.csv", "wb") do |csv|
      csv << ["name", "email"]
      @unrecognized_authors.each do |author|
        author_detail = []
        author_detail << author[:name]
        author_detail << author[:email]
        info "#{author_detail} is unrecognized\n"
        csv << author_detail
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
  builder.use ThrottleMiddleware
  builder.use Octokit::Middleware::FollowRedirects
  builder.use Octokit::Response::RaiseError
  builder.use Octokit::Response::FeedParser
  builder.response :logger if @debug
  builder.adapter Faraday.default_adapter
end

Octokit.configure do |kit|
  kit.auto_paginate = true
  kit.middleware = stack
end

options[:client] = Octokit::Client.new

InactiveMemberSearch.new(options)
