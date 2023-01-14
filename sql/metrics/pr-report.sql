/* 
 * This pulls a report of pull requests including the repo name, user name, 
 * files included, times it was created/updated/merged, and comments.
 *
 * If you know the organization ID you're interested in, uncomment and put it
 * in line 27 to filter this to a specific org.  Otherwise, this query returns
 * all pull requests in GitHub Enterprise Server.
 */
SELECT
	r.name,
	u.login,
	path as filename,
	p.id as pr_id,
	p.created_at as created_time,
	p.updated_at as updated_time,
	p.merged_at as merged_time,
	CONVERT(body
		USING utf8) as comment
FROM
	github_enterprise.pull_request_review_comments c
JOIN github_enterprise.users u ON
	u.id = c.user_id
JOIN github_enterprise.pull_requests p ON
	p.id = c.pull_request_id
JOIN github_enterprise.repositories r ON
	r.id = c.repository_id
-- WHERE r.owner_id = (org id here)
;