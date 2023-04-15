/* 
 * This query returns a list of organizations or users with staff_notes.
 *
 * Optionally, you can search for a specific string in the WHERE clause.
 */
SELECT
	u.login as "User Name",
	u.type as Type,
	s.note as Note,
	s.created_at as "Created At",
	s.updated_at as "Last Updated"
FROM
	github_enterprise.staff_notes s
JOIN github_enterprise.users u ON
	s.notable_id = u.id
-- WHERE
-- 	s.note LIKE '%string-to-search-for%';