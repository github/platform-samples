require 'octokit.rb'

if ARGV.length != 1
  $stderr.puts "Pass in the name of the organization you're interested in checking."
  exit 1
end

# !!! DO NOT EVER USE HARD-CODED VALUES IN A REAL APP !!!
# Instead, set and test environment variables, like below
client = Octokit::Client.new(:access_token => ENV['MY_PERSONAL_TOKEN'])

ORG = ARGV[0].to_s

client.organization_members(ORG, { :filter => "2fa_disabled" }).each do |user|
  puts "#{user[:login]} does not have 2FA enabled, and yet is a member of #{ORG}!"
end
