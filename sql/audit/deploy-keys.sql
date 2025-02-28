/* 
 * This query returns SSH deploy keys and what repo they're tied to, when last
 * used, etc.
 */
SELECT
	d.title as key_name,
	d.created_at,
	d.updated_at,
	d.verified_at,
	d.accessed_at as last_used,
	length(d.key) as key_length,
	u.login as created_by_name,
	d.created_by as created_by_type,
	r.name as repo_name,
	x.login as repo_owner_name
FROM
	github_enterprise.public_keys d
LEFT JOIN github_enterprise.users u ON
	d.creator_id = u.id
LEFT JOIN github_enterprise.repositories r ON
	d.repository_id = r.id
LEFT JOIN (
	SELECT
		id,
		login,
		type
	FROM
		github_enterprise.users u2
    ) x ON
	x.id = r.owner_id
WHERE
	d.repository_id IS NOT NULL;