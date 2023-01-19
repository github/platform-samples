/* 
 * This lists the "size" of each language in each repository and when the repo
 * was last updated.
 */
SELECT
	r.name,
	l.updated_at,
	l.public,
	l.size,
	n.name
FROM
	github_enterprise.languages l
JOIN github_enterprise.language_names n ON
	l.language_name_id = n.id
JOIN github_enterprise.repositories r ON
	l.repository_id = r.id;