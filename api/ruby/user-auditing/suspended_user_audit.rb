#!/usr/bin/env ruby

# Suspended User Audit - Generated with Octokitchen https://github.com/kylemacey/octokitchen

# Dependencies
require "octokit"

Octokit.configure do |kit|
  kit.auto_paginate = true
end

client = Octokit::Client.new
users = client.all_users
n = 1
puts "Aggregating users..."
full_users = users.map { |u|
  print "\r#{n}/#{users.count}"
  n += 1
  client.user(u.login) rescue nil;
}

suspended = full_users.select do |u|
  next unless u
  !u.suspended_at.nil? rescue false;
end

active = full_users.select do |u|
  next unless u
  u.suspended_at.nil? rescue false;
end

seconds_in_two_days = 60 * # seconds in an minute
                      60 * # minutes in an hour
                      48   # hours in 2 days

recent = suspended.select do |u|
  u[:suspended_at] > (Time.now - seconds_in_two_days)
end

puts ""
puts ""
puts "Suspended: #{suspended.count}"
puts "Recently Suspended: #{recent.count}"
puts "Active: #{active.count}"

puts ""

print "Unsuspend recently suspended users? (y/N) "

if gets.rstrip == "y"
  ent = Octokit::EnterpriseAdminClient.new

  recent.each do |u|
    ent.unsuspend u[:login]
  end
end
