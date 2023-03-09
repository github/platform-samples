/* 
 * This pulls a list of all repositories in GHES with details on
 * commit count, PR count, Issue count, Disk usage, Repo admins, Org owners, LFS usage, etc.
 * Please include the LIMIT clause at the bottom if you are concern of the number of results.
 */
SELECT repo.id as "Repo Id",
	repo.owner_login as "Org Name",
	repo.name as "Repository",
	IFNULL(repo.active, 0) as "is active",
	IFNULL(commits.commit_count, 0) as "Commit Count",
	IFNULL(pr.count, 0) as "PR Count",
	IFNULL(prr.count, 0) as "PR Review Count",
	IFNULL(issue.count, 0) as "Issue Count",
	IFNULL(pb.branch_count, 0) as "Protected Branch Count",
	IFNULL(pb.branch_names, '') as "Protected Branch Names",
	repo.public as "is public",
	IFNULL(internal.internal, 0) as "is internal",
	repo.public_fork_count as "Fork Child Count",
	IFNULL(repo2.is_fork, 0) as "is Fork",
	IFNULL(CONCAT(repo2.owner_login, "/", repo2.name), '') as "Fork Parent",
	CAST(repo.disk_usage / 1024 AS DECIMAL (10, 3)) as "Disk Usage (MB)",
	CAST(
		IFNULL(lfs_repo.lfs_size, 0) / 1024 / 1024 / 1024 AS DECIMAL (10, 2)
	) as "LFS Usage (GB)",
	IFNULL(lfs_repo.last_lfs_push, '') as "Last LFS Push",
	IFNULL(language.name, "none") as "Language",
	IFNULL(releases.count, 0) as "Release Count",
	CAST(
		IFNULL(release_size.release_asset_disk_size, 0) / 1024 / 1024 / 1024 AS DECIMAL (10, 2)
	) as "Releases Usage (GB)",
	IFNULL(projects.count, 0) as "Projects Count",
	IFNULL(hooks.count, 0) as "Hooks Count",
	IFNULL(admins.login, '') as "Repo Admins",
	IFNULL(team_admin.team_admins, '') as "Team Admins",
	IFNULL(org_admin.org_owners, '') as "Org Admins",
	repo.locked as "is Locked",
	repo.created_at as "Created at",
	repo.updated_at as "Updated at",
	repo.pushed_at as "Last Code Push",
	owner.type as "Org Type",
	repo.owner_id as "User/Owner Id",
	owner.created_at as "User/Owner Created",
	owner.updated_at as "User/Owner Updated",
	IFNULL(owner.suspended_at, '') as "User/Owner Suspended"
FROM repositories repo
	LEFT JOIN users owner ON owner.id = repo.owner_id
	LEFT JOIN language_names language ON repo.primary_language_name_id = language.id
	LEFT JOIN (
		SELECT COUNT(id) as count,
			repository_id
		FROM pull_requests
		GROUP BY repository_id
	) pr on pr.repository_id = repo.id
	LEFT JOIN (
		SELECT COUNT(id) as count,
			repository_id
		FROM pull_request_reviews
		GROUP BY repository_id
	) prr on prr.repository_id = repo.id
	LEFT JOIN (
		SELECT COUNT(id) as count,
			repository_id
		FROM issues
		WHERE has_pull_request = 0
		GROUP BY repository_id
	) issue on issue.repository_id = repo.id
	LEFT JOIN (
		SELECT 1 as "internal",
			repository_id
		FROM internal_repositories
	) internal on internal.repository_id = repo.id
	LEFT JOIN (
		SELECT SUM(commit_count) as "commit_count",
			repository_id
		FROM commit_contributions
		GROUP BY repository_id
	) commits on commits.repository_id = repo.id
	LEFT JOIN (
		SELECT COUNT(id) as branch_count,
			repository_id,
			GROUP_CONCAT(name SEPARATOR ';') as branch_names
		FROM protected_branches
		GROUP BY repository_id
	) pb on pb.repository_id = repo.id
	LEFT JOIN (
		SELECT 1 as is_fork,
			id,
			name,
			parent_id,
			owner_login
		FROM repositories
	) repo2 on repo2.id = repo.parent_id
	LEFT JOIN (
		SELECT COUNT(id) as count,
			repository_id
		FROM releases
		GROUP BY repository_id
	) releases on releases.repository_id = repo.id
	LEFT JOIN (
		SELECT count(id) as count,
			owner_id
		FROM projects
		WHERE owner_type = "Repository"
		GROUP BY owner_id
	) projects on projects.owner_id = repo.id
	LEFT JOIN (
		SELECT count(id) as count,
			installation_target_id
		FROM hooks
		WHERE installation_target_type = "Repository"
		GROUP BY installation_target_id
	) hooks on hooks.installation_target_id = repo.id
	LEFT JOIN (
		SELECT a.subject_id,
			GROUP_CONCAT(uu.login SEPARATOR ';') as login
		FROM abilities a
			LEFT JOIN (
				SELECT u.id,
					u.login
				FROM users u
			) uu ON uu.id = a.actor_id
		WHERE a.subject_type = "Repository"
			AND a.actor_type = "User"
			AND a.action = 2
		GROUP BY a.subject_id
	) admins on admins.subject_id = repo.id
	LEFT JOIN (
		SELECT a.subject_id as sub_repo_id,
			GROUP_CONCAT(members.team_admins) as team_admins
		FROM abilities a
			LEFT JOIN (
				SELECT team.subject_id,
					GROUP_CONCAT(uu.login SEPARATOR ';') as team_admins
				FROM abilities team
					LEFT JOIN (
						SELECT id,
							login
						FROM users
					) uu ON uu.id = team.actor_id
				WHERE team.subject_type = "Team"
					AND team.actor_type = "User"
				GROUP BY team.subject_id
			) members ON members.subject_id = a.actor_id
		WHERE a.subject_type = "Repository"
			AND a.actor_type = "Team"
			AND a.action = 2
		GROUP BY a.subject_id
	) team_admin on team_admin.sub_repo_id = repo.id
	LEFT JOIN (
		SELECT a.subject_id,
			GROUP_CONCAT(uu.login SEPARATOR ';') as org_owners
		FROM abilities a
			LEFT JOIN (
				SELECT id,
					login
				FROM users
			) uu ON uu.id = a.actor_id
		WHERE a.subject_type = "Organization"
			AND a.action = 2
		GROUP BY a.subject_id
	) org_admin ON org_admin.subject_id = repo.owner_id
	LEFT JOIN (
		SELECT originating_repository_id,
			SUM(size) as lfs_size,
			MAX(created_at) as last_lfs_push
		FROM media_blobs
		GROUP BY originating_repository_id
	) as lfs_repo on lfs_repo.originating_repository_id = repo.id
	LEFT JOIN (
		SELECT repository_id,
			SUM(size) as release_asset_disk_size
		FROM release_assets
		GROUP BY repository_id
	) release_size on release_size.repository_id = repo.id
ORDER BY repo.owner_login,
	repo.name 
-- LIMIT 100
