/* 
 * This pulls a "high score" report of all users, all commits, from all time.
 */
SELECT
	u.login,
	SUM(commit_count)
FROM
	github_enterprise.commit_contributions c
JOIN github_enterprise.users u ON
	u.id = c.user_id
GROUP BY
	user_id
ORDER BY
	COUNT(c.user_id) DESC;