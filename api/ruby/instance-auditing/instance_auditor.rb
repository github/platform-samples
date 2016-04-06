
# GitHub & GitHub Enterprise Instance auditor
# =======================================
#
# Usage: ruby instance_audit.rb
#
# These environment variables must be set:
# - GITHUB_TOKEN: A valid personal access token with Organzation admin priviliges
# - GITHUB_API_ENDPOINT: A valid GitHub/GitHub Enterprise API endpoint URL
#                        (use https://api.github.com for GitHub.com auditing)
#
# Requires the Octokit Rubygem: https://github.com/octokit/octokit.rb
# Requires the axlsx Rubygem:   https://github.com/randym/axlsx

require 'octokit.rb'
require 'axlsx'

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

client = Octokit::Client.new

Axlsx::Package.new do |p|
  client.organizations.each do |org|
    p.workbook.add_worksheet(:name => org[:login]) do |sheet|
      sheet.add_row %w{Organization Team Repo User Access}
      client.organization_teams(org[:login]).each do |team|
        client.team_repos(team[:id]).each do |repo|
          client.team_members(team[:id]).each do |user|
            sheet.add_row [org[:login], team[:name], repo[:name], user[:login], team[:permission]]
          end
        end
      end
    end
  end
  p.use_shared_strings = true
  p.serialize("#{Time.now.strftime "%Y-%m-%d"}-audit.xlsx")
end
