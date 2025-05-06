/* 
 * These are custom tabs set by a repository owner that show up to their users.
 */
SELECT
	t.anchor as name,
	t.url,
	t.created_at,
	t.updated_at,
	r.name as repo_name,
	u.login as owner_name,
	u.type as owner_type
FROM
	github_enterprise.tabs t
JOIN github_enterprise.repositories r ON
	t.repository_id = r.id
JOIN github_enterprise.users u ON
	r.owner_id = u.id;