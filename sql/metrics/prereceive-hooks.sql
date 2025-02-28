/* 
 * This returns a list of pre-receive hooks that are enabled by each repository
 * and who owns the repo.
 */
SELECT
	h.name as hook_name,
	r.name as repo_name,
	u.login as owner_name
FROM
	github_enterprise.pre_receive_hook_targets t
JOIN github_enterprise.pre_receive_hooks h ON
	h.id = t.hook_id
JOIN github_enterprise.repositories r ON
	r.id = t.hookable_id
JOIN github_enterprise.users u ON
	r.owner_id = u.id;