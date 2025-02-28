/* 
 * This pulls a list of all apps, tokens, and scopes associated with that token
 * as well as when it was last used, created, and updated.
 */
SELECT
	z.id,
	u.login as owner_name,
	u.type as owner_type,
	a.name as app_name,
	z.accessed_at,
	z.created_at,
	z.updated_at,
	z.description,
	z.scopes
FROM
	github_enterprise.oauth_authorizations z
JOIN github_enterprise.users u ON
	z.user_id = u.id
LEFT JOIN github_enterprise.oauth_applications a ON
	z.application_id = a.id;