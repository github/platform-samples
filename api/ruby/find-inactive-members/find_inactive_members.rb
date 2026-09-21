require "csv"
require "octokit"
require "optparse"
require "optparse/date"
require "json"
require "fileutils"

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

    if options[:checkpoint]
      @checkpoint = true
      FileUtils.mkdir_p "data/activities"
    end

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
    info "Rate limit: #{@client.rate_limit.remaining}/#{@client.rate_limit.limit}\n"
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
    members = load_file("data/members.json")
    if members == nil
      info "Collecting organization members from API\n"
      members = @client.organization_members(@organization)
      info "Organization members collected, saving data...\n"
      save_file("data/members.json", members.map(&:to_h))
    end

    info "Finding #{@organization} members "
    @members = members.collect do |m|
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
    repositories = load_file("data/repositories.json")
    if repositories == nil
      repositories = @client.organization_repositories(@organization)
      save_file("data/repositories.json", repositories.map(&:to_h))
    end

    info "Gathering a list of repositories..."
    # get all repos in the organizaton and place into a hash
    @repositories = repositories.collect do |repo|
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
      file_name = "data/activities/" + sanitize_filename(repo) + "-commits_since.json"
      commits_since = load_file(file_name, :symbolize_names => true)
      if commits_since == nil
        commits_since = @client.commits_since(repo, @date).map(&:to_h)
        save_file(file_name, commits_since)
      end
      commits_since.each do |commit|
        # if commmitter is a member of the org and not active, make active
        if commit[:author].nil?
          add_unrecognized_author(commit[:commit][:author])
          next
        end
        if t = @members.find {|member| member[:login] == commit[:author][:login] && member[:active] == false }
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
    file_name = "data/activities/" + sanitize_filename(repo) + "-list_issues.json"
    list_issues = load_file(file_name, :symbolize_names => true)
    if list_issues == nil
      list_issues = @client.list_issues(repo, { :since => date }).map(&:to_h)
      save_file(file_name, list_issues)
    end
    list_issues.each do |issue|
      # if there's no user (ghost user?) then skip this   // THIS NEEDS BETTER VALIDATION
      if issue[:user].nil?
        next
      end
      # if creator is a member of the org and not active, make active
      if t = @members.find {|member| member[:login] == issue[:user][:login] && member[:active] == false }
        make_active(t[:login])
      end
    rescue Octokit::NotFound
      #API responds with a 404 (instead of an empty set) when repo is a private fork for security advisories
      info "...no access to issues in this repo ..."
    end
  end

  def issue_comment_activity(repo, date=@date)
    # get all issue comments after specified date and iterate
    info "...Issue comments"
    file_name = "data/activities/" + sanitize_filename(repo) + "-issues_comments.json"
    issues_comments = load_file(file_name, :symbolize_names => true)
    if issues_comments == nil
      issues_comments = @client.issues_comments(repo, { :since => date }).map(&:to_h)
      save_file(file_name, issues_comments)
    end
    issues_comments.each do |comment|
      # if there's no user (ghost user?) then skip this   // THIS NEEDS BETTER VALIDATION
      if comment[:user].nil?
        next
      end
      # if commenter is a member of the org and not active, make active
      if t = @members.find {|member| member[:login] == comment[:user][:login] && member[:active] == false }
        make_active(t[:login])
      end
    rescue Octokit::NotFound
      #API responds with a 404 (instead of an empty set) when repo is a private fork for security advisories
      info "...no access to issue comments in this repo ..."
    end
  end

  def pr_activity(repo, date=@date)
    # get all pull request comments comments after specified date and iterate
    info "...Pull Request comments"
    file_name = "data/activities/" + sanitize_filename(repo) + "-pull_requests_comments.json"
    pull_requests_comments = load_file(file_name, :symbolize_names => true)
    if pull_requests_comments == nil
      pull_requests_comments = @client.pull_requests_comments(repo, { :since => date }).map(&:to_h)
      save_file(file_name, pull_requests_comments)
    end
    pull_requests_comments.each do |comment|
      # if there's no user (ghost user?) then skip this   // THIS NEEDS BETTER VALIDATION
      if comment[:user].nil?
        next
      end
      # if commenter is a member of the org and not active, make active
      if t = @members.find {|member| member[:login] == comment[:user][:login] && member[:active] == false }
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

  def load_file(filename, parseOptions = {})
    if @checkpoint != true
      return nil
    end
    begin
      # info "Trying to load #{filename}.\n"
      data = JSON.parse(File.read(filename), parseOptions)
      # info "File #{filename} has been loaded.\n"
      return data
    rescue => exception
      # info "Cannot load #{filename}\n"
      # info "#{exception}\n"
      return nil
    end
  end

  def save_file(filename, data)
    if @checkpoint != true
      return
    end
    info "Saving data to #{filename}\n"
    File.open(filename, 'w') do |f|
      f.write(JSON.generate(data))
    end
    info "File saved to #{filename}\n"
  end

  def sanitize_filename(filename)
    # Split the name when finding a period which is preceded by some
    # character, and is followed by some character other than a period,
    # if there is no following period that is followed by something
    # other than a period (yeah, confusing, I know)
    fn = filename.split /(?<=.)\.(?=[^.])(?!.*\.[^.])/m

    # We now have one or two parts (depending on whether we could find
    # a suitable period). For each of these parts, replace any unwanted
    # sequence of characters with an underscore
    fn.map! { |s| s.gsub /[^a-z0-9\-]+/i, '_' }

    # Finally, join the parts with a period and return the result
    return fn.join '.'
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

  opts.on('--checkpoint', "Enable file checkpoint, to be able to continue from failed request") do |c|
    options[:checkpoint] = c
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
  kit.connection_options = {
    request: {
      open_timeout: 10,
      timeout: 10,
    }
  }
end

options[:client] = Octokit::Client.new

InactiveMemberSearch.new(options)
