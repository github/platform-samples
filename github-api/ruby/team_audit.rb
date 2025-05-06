# GitHub & GitHub Enterprise Team auditor
# =======================================
#
# Usage: ruby team_audit.rb <orgname>
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

begin
  teams = client.organization_teams(ORG)
rescue Octokit::NotFound
  puts "FATAL: Organization not found with name: #{ORG} at #{API_ENDPOINT}."
end

dirname = [ORG, Date.today.to_s].join('-')

unless File.exists? dirname
  dir = Dir.mkdir dirname
end

teams.each do |team|
  # Create Team Member Sheet
  begin
    m_filename = [team[:name], "Members"].join(' - ')
    File.open("#{dirname}/#{m_filename}.csv", 'w') { |f| f.write client.team_members(team[:id]).map { |m| [m[:login], m[:site_admin]].join(', ') }.unshift('username, site_admin').join("\n") }
  rescue Octokit::NotFound
    puts "You do not have access to view members in #{team[:name]}"

  end

  # Create Team Repos Sheet
  begin
    m_filename = [team[:name], "Repositories"].join(' - ')
    File.open("#{dirname}/#{m_filename}.csv", 'w') { |f| f.write client.team_repositories(team[:id]).map { |m| [m[:full_name], team[:permission]].join(', ') }.unshift('repo_name, access').join("\n") }
  rescue Octokit::NotFound
    puts "You do not have access to view repositories in #{team[:name]}"
  end
end

puts "Output written to #{dirname}/"
