# Script to update the domain name for links in issue & pr comments.
require 'octokit'
require 'optparse'
require 'ostruct'

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
  kit.api_endpoint = "https://#{hostname}/api/v3"
  kit.access_token = access_token
  kit.auto_paginate = true
end

unless ARGV.length >= 2
  puts "Specify domain names to change using the following format:"
  puts "- change-domains.rb old_domain new_domain"
  exit 1
end

options = OpenStruct.new
options.noop = false

OptionParser.new do |parser|
  parser.on("-n", "--noop", "Find the links, but don't update the content.", "Pipe this to a CSV file for a report", "of all links that will be changed.") do |v|
    options.noop = v
  end
end.parse!


# Extract links to attached files using regexp
# Looks for the raw markdown formatted image link formatted like this:
# [image description](https://media.octodemo.com/user/267/files/e014c3e4-889c-11e6-8637-1f16c810cfe3)
# example pattern = /\[[^\]]*\]\((https:\/\/media.octodemo.com[^\)]*\/files\/[^\)]*)\)/
old_domain    = ARGV[0]
new_domain    = ARGV[1]
media_pattern = /\[[^\]]*\]\((https:\/\/media.#{old_domain}[^\)]*\/user\/\d*\/files\/[^\)]*)\)/

Octokit.repositories.map{|repo| repo.full_name}.each do |r|
  # Extract issues containing links to attached files
  issues = Octokit.issues(r, {state: :all}).select do |i|
    unless i.body.nil?
      i.body.match(media_pattern)
    end
  end
  issues.each do |issue|
    # Extract the link pattern from issues' body
    matched_links = issue.body.scan(media_pattern)
    matched_links.each do |file|
      puts "#{issue.html_url},#{file[0]}"
      # Rewrite link with "media" subdomain to "/storage" on the new domain
      new_link = file[0].gsub("media.#{old_domain}", "#{new_domain}/storage")
      new_body = issue.body.gsub(file[0], new_link)
      unless options.noop == true
        Octokit.update_issue(r, issue.number, :body => new_body)
        puts "Updated Issue/PR: #{issue.html_url}"
      end
    end
  end

  # Issue comments as well (including pull request comments)
  issue_comments = Octokit.issues_comments(r).select do |ic|
      unless ic.body.nil?
        ic.body.match(media_pattern)
      end
  end
  unless issue_comments.nil?
    issue_comments.each do |issue_comment|
      matched_links = issue_comment.body.scan(media_pattern)
      matched_links.each do |file|
        puts "#{issue_comment.html_url},#{file[0]}"
        # Rewrite link with "media" subdomain to "/storage" on the new domain
        new_link = file[0].gsub("media.#{old_domain}", "#{new_domain}/storage")
        new_comment = issue_comment.body.gsub(file[0], new_link)
        unless options.noop == true
          Octokit.update_comment(r, issue_comment.id, new_comment)
          puts "Updated Issue/PR Comment: #{issue_comment.html_url}"
        end
      end
    end
  end

  # Pull request review comments as well
  #
  # > Disabled >= v2.8. Issues/PRs and associated comments are included in the above methods.
  # > Will need to add Review comments with the next release of Octokit.
  # > See https://github.com/octokit/octokit.rb/pull/860 for PR that implements
  # > the Preview version of the Review API.
  #
  # pr_comments = Octokit.pulls_comments(r).select do |prc|
  #   unless prc.body.nil?
  #     prc.body.match(media_pattern)
  #   end
  # end
  # unless pr_comments.nil?
  #   pr_comments.each do |pr_comment|
  #     matched_links = pr_comment.body.scan(media_pattern)
  #     matched_links.each do |file|
  #       puts "#{pr_comment.html_url},#{file[0]}"
  #     end
  #   end
  # end
end
