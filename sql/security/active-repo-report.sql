/*
 * This pulls a list of all detected HIGH and CRITICAL vulnerabilities from
 * repositories pushed to in the past 90 days.  It also returns who owns it and
 * further details on the exact vulnerability.
 *
 * If you comment line 32, it will both root and fork repositories.  As is, 
 * it will only report root repos.
 */
SELECT
	r.name AS repo_name,
	u.login AS repo_owner,
	u.type AS owner_type,
	pushed_at AS last_update,
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
WHERE
	(v.severity = "critical"
		OR v.severity = "high")
	AND DATEDIFF(NOW(), r.pushed_at) < 91
	AND r.parent_id IS NULL
ORDER BY
	last_update DESC;