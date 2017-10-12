require 'octokit'

# Check for environment variables
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

# Get a list of all users
begin
  users = Octokit.all_users
rescue
  puts "\nAn error occurred."
  puts "\nPlease check your hostname ('#{hostname}') and access token ('#{access_token}')."
  exit 1
end

total = users.length
puts "Found #{total} users."
puts

count = 1

# Print each user's public SSH keys
users.each do |user|
  # Skip organization accounts, which are included in the list of users
  # but don't have any public SSH keys
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
