/* 
 * This pulls a list of all github apps, who owns them, and when they were 
 * created or updated.
 */
SELECT
	i.id,
	i.bot_id,
	i.name as integration_name,
	u.login as owner,
	u.type,
	i.url,
	i.created_at,
	i.updated_at,
	i.public,
	i.slug as friendly_name,
	i.public
FROM
	github_enterprise.integrations i
JOIN github_enterprise.users u ON
	i.owner_id = u.id;