require 'octokit.rb'

begin
  ACCESS_TOKEN = ENV.fetch("GITHUB_TOKEN")
  HOSTNAME = ENV.fetch("GITHUB_HOSTNAME")
rescue KeyError
  $stderr.puts "To run this script, please set the following environment variables:"
  $stderr.puts "- GITHUB_TOKEN: A valid access token with Organzation admin priviliges"
  $stderr.puts "- GITHUB_HOSTNAME: A valid GitHub Enterprise hostname"
  exit 1
end

Octokit.configure do |kit|
  kit.api_endpoint = "#{HOSTNAME}/api/v3"
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
