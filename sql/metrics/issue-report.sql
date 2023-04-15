/* 
 * This query returns a report of active issues within the past X days.
 */
SELECT
	r.name as repo_name,
	u.login as created_by,
	v.login as assigned_to,
	i.state as issue_state,
	i.created_at,
	i.updated_at,
	i.closed_at,
	i.issue_comments_count,
	DATEDIFF(i.closed_at, i.created_at) as days_open
FROM
	github_enterprise.issues i
LEFT JOIN github_enterprise.users u ON
	i.user_id = u.id
LEFT JOIN github_enterprise.users v ON
	i.assignee_id = v.id
INNER JOIN github_enterprise.repositories r ON
	i.repository_id = r.id
WHERE
	DATEDIFF(NOW(), i.created_at) <= 365
ORDER BY
	days_open DESC;