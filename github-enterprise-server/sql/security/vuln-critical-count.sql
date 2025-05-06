/* 
 * This pulls a count of repos affected by each _critical_ vulnerability.
 */
SELECT
	v.id,
	v.cve_id,
	v.ghsa_id,
	v.white_source_id,
	v.published_at as published,
	v.external_reference,
	v.platform as ecosystem,
	COUNT(z.vulnerability_id) as repo_count
FROM
	github_enterprise.repository_vulnerability_alerts z
JOIN github_enterprise.vulnerabilities v ON
	z.vulnerability_id = v.id
WHERE
	v.severity = 'critical'
GROUP BY
	v.id
ORDER BY
	COUNT(z.vulnerability_id) DESC;