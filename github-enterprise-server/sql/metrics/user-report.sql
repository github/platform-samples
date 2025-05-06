/*
 * This query returns the username, id, created/suspended date, issues created
 * for all time and in the past 30 days, number of repos owned, and how many
 * pull requests they've opened.
 */
SELECT
	u.login,
	u.id,
	u.created_at,
	u.suspended_at,
	i.cnt issues_created_all_time,
	i2.cnt issues_created_30_days,
	r.cnt repos_owned,
	pr.cnt prs_opened
FROM
	github_enterprise.users u
LEFT JOIN (
	SELECT
		user_id,
		count(id) cnt
	FROM
		github_enterprise.issues
	GROUP BY
		user_id ) i ON
	i.user_id = u.id
LEFT JOIN (
	SELECT
		user_id,
		count(id) cnt
	FROM
		github_enterprise.issues
	WHERE
		DATEDIFF(NOW(), created_at) <= 30
	GROUP BY
		user_id ) i2 ON
	i2.user_id = u.id
LEFT JOIN (
	SELECT
		owner_id,
		count(id) cnt
	FROM
		github_enterprise.repositories
	GROUP BY
		owner_id ) r ON
	r.owner_id = u.id
LEFT JOIN (
	SELECT
		user_id,
		count(id) cnt
	FROM
		github_enterprise.pull_requests
	GROUP BY
		user_id ) pr ON
	pr.user_id = u.id
;
