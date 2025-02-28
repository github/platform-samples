/*
 * This query returns user SSH keys and when they were last used.
 */
SELECT
	d.title as key_name,
	d.created_at,
	d.updated_at,
	d.verified_at,
	d.accessed_at as last_used,
	length(d.key) as key_length,
	u.login as created_by_name,
	d.created_by as created_by_type
FROM
	github_enterprise.public_keys d
LEFT JOIN github_enterprise.users u ON
	d.creator_id = u.id
WHERE
	d.user_id IS NOT NULL;