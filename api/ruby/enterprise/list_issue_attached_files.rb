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

pattern = /\[[^\]]*\]\(([^\)]*)\)/
Octokit.repositories.map{|repo| repo.full_name}.each do |r|
  Octokit.issues(r, {state: :all}).select{|i| i.body.match(pattern)}.each{|mi| mi.body.scan(pattern).each{|s| puts "#{mi.html_url},#{s[0]}"}}
  Octokit.issues_comments(r).select{|ic| ic.body.match(pattern)}.each{|mic| mic.body.scan(pattern).each{|s| puts "#{mic.html_url},#{s[0]}"}}
  Octokit.pulls_comments(r).select{|prc| prc.body.match(pattern)}.each{|mprc| mprc.body.scan(pattern).each{|s| puts "#{mprc.html_url},#{s[0]}"}}
end
