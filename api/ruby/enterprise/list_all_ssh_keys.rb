require 'octokit'

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

Octokit.configure do |c|
  c.api_endpoint = "#{hostname}/api/v3"
  c.access_token = access_token
end

Octokit.auto_paginate = true

users = Octokit.all_users

total = users.length
puts "Found #{total} users."
puts

count = 1

users.each do |user|
  if user.type == 'Organization'
    puts "No keys for #{user.login} (user ##{count} of #{total})."
    count += 1
    next
  end

  keys = Octokit.user_keys(user.login)

  if keys.empty?
    puts "No keys for #{user.login} (user ##{count} of #{total})."
  else
    puts
    puts "=================================================="
    puts "Keys for #{user.login} (user ##{count} of #{total}):"
    keys.each do |key|
      puts
      puts key.key
    end
    puts "=================================================="
    puts
  end

  count += 1
end