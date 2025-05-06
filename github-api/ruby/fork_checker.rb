require 'octokit.rb'

if ARGV.length != 1
  $stderr.puts "Pass in the name of the repository you're interested in checking as an argument, as <owner>/<repo>."
  exit 1
end

# !!! DO NOT EVER USE HARD-CODED VALUES IN A REAL APP !!!
# Instead, set and test environment variables, like below
client = Octokit::Client.new(:access_token => ENV['MY_PERSONAL_TOKEN'])

REPO = ARGV[0].to_s
owner = REPO.split("/")[0]

client.forks REPO
forks = client.last_response.data
loop do
  last_response = client.last_response
  break if last_response.rels[:next].nil?
  forks.concat last_response.rels[:next].get.data
end

forks.map{ |f| f[:owner][:login] }.each do |user|
  unless client.organization_member?(owner, user)
    puts "#{user} forked #{REPO}, but is not a member of #{owner}!"
  end
end
