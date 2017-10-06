require "octokit"
require "csv"

if ARGV.length > 3 || ARGV.length == 0
  puts "usage: ruby find_inactive_members.rb orgName YYYY-MM-DD purge(optional)"
  exit(1)
end

if ARGV[2] == "purge"
  print "Do you really want to purge all members of #{ARGV[0]} inactive since #{ARGV[1]}? y/n: "
  response = STDIN.gets.chomp
  if response != "y"
    exit(1)
  end
end

# initialize octokit
Octokit.auto_paginate = true
@client = Octokit::Client.new

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
  print "...comments"
  @client.issues_comments(repo["full_name"], { :since => ARGV[1]}).each do |comment|
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
        puts "removing the member"
        # @client.remove_organization_member(ORGANIZATION, member["login"])
      end
    end
  end

end
