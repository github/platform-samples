/* 
 * This query generates a monthly summary of commit activity by committed date.
 */
SELECT
	month(c.committed_date) as month,
	year(c.committed_date) as year,
	sum(c.commit_count) as commits
FROM
	github_enterprise.commit_contributions c
GROUP BY
	month,
	year
ORDER BY
	year,
	month