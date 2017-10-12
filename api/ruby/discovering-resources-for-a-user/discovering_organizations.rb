require 'octokit'

Octokit.auto_paginate = true

# !!! DO NOT EVER USE HARD-CODED VALUES IN A REAL APP !!!
# Instead, set and test environment variables, like below.
client = Octokit::Client.new :access_token => ENV["OAUTH_ACCESS_TOKEN"]

client.organizations.each do |organization|
  puts "User belongs to the #{organization[:login]} organization."
end
