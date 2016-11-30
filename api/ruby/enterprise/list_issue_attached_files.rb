require 'octokit'

# Lists all files attached to issues and pull requests on a instance.
# The list doesn't contain files that are uploaded but not referenced.

## Check for environment variables
begin
  access_token = ENV.fetch("GITHUB_TOKEN")
  hostname = ENV.fetch("GITHUB_HOSTNAME")
rescue KeyError
  puts
  puts "To run this script, please set the following environment variables:"
  puts "- GITHUB_TOKEN: A valid access token"
  puts "- GITHUB_HOSTNAME: A valid GitHub Enterprise hostname"
  exit 1
end

# Set up Octokit
Octokit.configure do |kit|
  kit.api_endpoint = "#{hostname}/api/v3"
  kit.access_token = access_token
  kit.auto_paginate = true
end

# Extract links to attached files using regexp
pattern = /\[[^\]]*\]\((#{hostname}[^\)]*\/files\/[^\)]*)\)/

Octokit.repositories.map{|repo| repo.full_name}.each do |r|
  # Extract issues containing links to attached files
  issues = Octokit.issues(r, {state: :all}).select do |i|
    i.body.match(pattern)
  end
  issues.each do |issue|
    # Extract the link pattern from issues' body
    matched_links = issue.body.scan(pattern)
    matched_links.each do |file|
      puts "#{issue.html_url},#{file[0]}"
    end
  end

  # Issue comments as well (including pull request comments)
  issue_comments = Octokit.issues_comments(r).select do |ic|
    ic.body.match(pattern)
  end
  issue_comments.each do |issue_comment|
    matched_links = issue_comment.body.scan(pattern)
    matched_links.each do |file|
      puts "#{issue_comment.html_url},#{file[0]}"
    end
  end

  # Pull request review comments as well
  pr_comments = Octokit.pulls_comments(r).select do |prc|
    prc.body.match(pattern)
  end
  pr_comments.each do |pr_comment|
    matched_links = pr_comment.body.scan(pattern)
    matched_links.each do |file|
      puts "#{pr_comment.html_url},#{file[0]}"
    end
  end
end
