/* 
 * This brings up the list of REPOSITORY webhooks that have been active in the
 * past week, who owns them, and where the webhook goes.
 */
SELECT
	DISTINCT h.id,
	u.login as creator,
	h.updated_at,
	r.name as repo_name,
	u.login as repo_owner,
	u.type as owner_type,
	c.value as url,
	MAX(l.delivered_at) as latest_delivery
FROM
	github_enterprise.hooks h
JOIN github_enterprise.hook_config_attributes c ON
	h.id = c.hook_id
JOIN github_enterprise.users u ON
	h.creator_id = u.id
JOIN github_enterprise.hookshot_delivery_logs l ON
	h.id = l.hook_id
JOIN github_enterprise.repositories r ON
	h.installation_target_id = r.id
WHERE
	c.key = 'url'
	AND h.installation_target_type = 'Repository'
GROUP BY
	h.id
ORDER BY
	MAX(l.delivered_at) DESC;