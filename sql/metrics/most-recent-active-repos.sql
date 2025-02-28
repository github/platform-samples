/* 
 * This pulls a list of repositories, when they were last updated, who owns 
 * them, and the disk space associated with each.
 */
SELECT
	r.name as repo_name,
	r.updated_at,
	r.disk_usage,
	u.login
FROM
	github_enterprise.repositories r
JOIN github_enterprise.users u ON
	r.owner_id = u.id
ORDER BY
	updated_at DESC;