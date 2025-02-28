/* 
 * This pulls a list of all detected vulnerabilities, what it is, who owns the 
 * associated repo, and when the repo was last updated.  This can be a very
 * large report!
 */
SELECT
	r.name as repo_name,
	u.login as repo_owner,
	u.type as owner_type,
	pushed_at as last_update,
	platform,
	severity,
	cve_id,
	ghsa_id,
	white_source_id,
	external_reference
FROM
	github_enterprise.repository_vulnerability_alerts z
JOIN github_enterprise.vulnerabilities v ON
	z.vulnerability_id = v.id
JOIN github_enterprise.repositories r ON
	z.repository_id = r.id
JOIN github_enterprise.users u ON
	r.owner_id = u.id
ORDER BY
	last_update DESC;