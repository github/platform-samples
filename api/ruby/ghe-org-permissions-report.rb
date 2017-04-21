#!/usr/bin/env ruby
# Generates a CSV report listing all organizations, their repositories,
# collaborators, effective permissions, teams, and team permissions
#
# Set OCTOKIT_ACCESS_TOKEN to a token with read:org scope owned by a site admin
# and OCTOKIT_API_ENDPOINT to http(s)://[your-hostname]/api/v3/
#
# Use `ghe-org-admin-promote` to make a site admin an owner of all
# organizations
require 'octokit'

ghe = Octokit::Client.new

PERMISSION_LEVELS = [:admin, :push, :pull]

def get_repo_teams(ghe, repo_full_name)
  teams = []
  ghe.repo_teams(repo_full_name).each do |t|
    teams << [t, ghe.team_members(t.id).map(&:login)]
  end

  teams
rescue Octokit::NotFound
  []
end

def get_org_role(ghe, org_name, user_login)
  ghe.org_membership(org_name, user: user_login).role
rescue Octokit::NotFound
  'outside-collaborator'
end

permission_list = []
ghe.orgs(ghe.user).each do |org|
  # We shouldn't try to get the org permissions if we're not an admin,
  # they'll be wrong or misleading
  if get_org_role(ghe, org.login, ghe.user.login) != 'admin'
    STDERR.puts "Skipping #{org.login} - not an organization admin"
    next
  end

  ghe.org_repos(org.login).each do |repo|
    # Fetch the collaborators on this repo (which includes their permissions).
    # This gives us the effective permissions that the user has, regardless of
    # how they've gotten those perms.
    collaborators = ghe.collabs(repo.full_name)

    # Find the teams that include the repo.
    teams = get_repo_teams(ghe, repo.full_name)

    collaborators.each do |collab|
      # Check the collaborator's role in the organization. If they're an admin,
      # they'll have admin access on all repos even if they're not in any teams.
      org_role = get_org_role(ghe, org.login, collab.login)
      perms = PERMISSION_LEVELS.find { |m| collab.permissions.send(m) }
      repo_access = [org.login, repo.name, collab.login, org_role, perms.to_s]

      team_memberships = []
      teams.each do |team, members|
        # For each team, see if the current collaborator is a member, and if so,
        # add the team and the permissions it would grant (which may not be the
        # user's effective permissions) to the list.
        # members = ghe.team_members(team.id).map(&:login)
        next unless members.include?(collab.login)

        team_memberships << [
          team.name,
          team.permission,
          ghe.team_membership(team.id, collab.login).role
        ]
      end

      # Try to identify the source of the collaborator's effective permission.
      # We can say for sure where it's being granted in these cases:
      #
      # - User is org admin: they'll always have admin perms, and the source
      #   is their org role.
      # - User is outside collaborator: They can't be a team member, so the
      #   source is the org assignment.
      # - User is org member and permissions are better than any team grants
      #   (e.g. effective permission is write, but team only grants read):
      #   source must be the default repo perms on the org.
      #
      # However, if the permissions are equal to those assigned by a team,
      # they may be granted by just the team, or by both the team and the
      # default repo perms. Since the orgs API doesn't tell us what the
      # default repo perms are, we can't say for sure. This could cause
      # confusion for an admin who wants to know "what do I need to do to
      # revoke this user's push access", but we'll just do the best we can and
      # say "team" in this case.
      best_team_permission = team_memberships.map do |tm|
        PERMISSION_LEVELS.index(tm[1].to_sym)
      end.sort.first

      perm_source =
        if org_role == 'admin'
          'org-admin'
        elsif org_role == 'outside-collaborator'
          'org-collaborator'
        elsif best_team_permission.nil? || PERMISSION_LEVELS.index(perms) < best_team_permission
          'org-default-permission'
        else
          'team'
        end

      if team_memberships.count > 0
        team_memberships.each do |m|
          permission_list << repo_access + [perm_source] + m
        end
      else
        permission_list << repo_access + [perm_source]
      end
    end
  end
end

puts 'Organization,Repository,User,Organization Role,Effective Permissions,Permissions Source,Team Name,Team Permission,Team Role'
permission_list.each { |p| puts p.join(',') }
