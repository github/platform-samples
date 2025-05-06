/*
 * This query returns a report of the owners of public repositories in GHES,
 * their user or organization email address, and how many repos they publicly
 * own.
 */
SELECT
	u.login,
	e.email,
	u.organization_billing_email,
	count(r.owner_id) as repo_count
FROM
	github_enterprise.repositories r
JOIN github_enterprise.users u ON
	r.owner_id = u.id
LEFT JOIN github_enterprise.user_emails e ON
	u.id = e.user_id
WHERE
	r.public = 1
GROUP BY
	u.login,
	e.email
ORDER BY
	repo_count DESC;