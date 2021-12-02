/* 
 * This query returns a count of all the reactions used in GHES for fun facts.
 */
SELECT
	content,
	COUNT(content) as count
FROM
	github_enterprise.reactions
GROUP BY
	content
ORDER BY
	COUNT(content) DESC;