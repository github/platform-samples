/*
 * This pulls the number of repositories containing any individual language
 * that have been pushed to in the past year.
 *
 * If you comment out the WHERE clause, it'll return the stats for your server
 * for all time.
 */
SELECT
	n.name as language_name,
	COUNT(l.language_name_id) as repo_count,
	ROUND(SUM(l.size) /(1024 * 1024)) as language_size_mb
FROM
	github_enterprise.languages l
	JOIN github_enterprise.language_names n ON l.language_name_id = n.id
	JOIN github_enterprise.repositories r ON l.repository_id = r.id
WHERE
	r.id IN (
		SELECT
			r.id
		FROM
			github_enterprise.repositories r
		WHERE
			DATEDIFF(NOW(), r.updated_at) < 365
	)
GROUP BY
	language_name_id
ORDER BY
	COUNT(l.language_name_id) DESC;