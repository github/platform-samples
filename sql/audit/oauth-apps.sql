/*
 * This pulls up a list of all OAuth apps and where they go, as well as when
 * they were last updated and what login they are associated with.
 */
SELECT
	o.name,
	o.url,
	o.callback_url,
	o.created_at,
	o.updated_at,
	u.login,
	u.type
FROM
	github_enterprise.oauth_applications o
JOIN github_enterprise.users u ON
	o.user_id = u.id;