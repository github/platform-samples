# GitHub & GitHub Enterprise 2FA auditor
# ======================================
#
# Usage: ruby 2fa_checker.rb <orgname>
#
# These environment variables must be set:
# - GITHUB_TOKEN: A valid personal access token with Organzation admin priviliges
# - GITHUB_API_ENDPOINT: A valid GitHub/GitHub Enterprise API endpoint URL
#                        (use https://api.github.com for GitHub.com auditing)
#
# Requires the Octokit Rubygem: https://github.com/octokit/octokit.rb

require 'octokit.rb'

begin
  ACCESS_TOKEN = ENV.fetch("GITHUB_TOKEN")
  API_ENDPOINT = ENV.fetch("GITHUB_API_ENDPOINT")
rescue KeyError
  $stderr.puts "To run this script, please set the following environment variables:"
  $stderr.puts "- GITHUB_TOKEN: A valid personal access token with Organzation admin priviliges"
  $stderr.puts "- GITHUB_API_ENDPOINT: A valid GitHub/GitHub Enterprise API endpoint URL"
  $stderr.puts "                       (use https://api.github.com for GitHub.com auditing)"
  exit 1
end

Octokit.configure do |kit|
  kit.api_endpoint = API_ENDPOINT
  kit.access_token = ACCESS_TOKEN
  kit.auto_paginate = true
end

if ARGV.length != 1
  $stderr.puts "Pass a valid Organization name to audit."
  exit 1
end

ORG = ARGV[0].to_s

client = Octokit::Client.new

users = client.organization_members(ORG, {:filter => "2fa_disabled"})

puts "The following #{users.count} users do not have 2FA enabled:\n\n"
users.each do |user|
  puts "#{user[:login]}"
end
