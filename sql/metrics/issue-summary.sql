/* 
 * This query generates a monthly summary of issues created.
 */
SELECT
	month(i.created_at) as month,
	year(i.created_at) as year,
	count(i.created_at) as issues
FROM
	github_enterprise.issues i
GROUP BY
	month,
	year
ORDER BY
	year,
	month