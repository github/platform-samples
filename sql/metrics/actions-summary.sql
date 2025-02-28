/* 
 * This query generates a monthly summary of runtime hours, seconds waiting 
 * in queue before dispatch, and job count for GitHub Actions usage.
 */
SELECT
	month(j.completed_at) as month,
	year(j.completed_at) as year,
	round(
		sum(
			unix_timestamp(j.completed_at) - unix_timestamp(
				coalesce(j.started_at, j.queued_at, j.created_at)
			)
		) / 3600
	) as compute_hours,
	round(
		avg(
			unix_timestamp(j.started_at) - unix_timestamp(j.queued_at)
		)
	) as seconds_queued,
	count(j.completed_at) as job_count
FROM
	github_enterprise.workflow_builds j
GROUP BY
	month,
	year
ORDER BY
	year,
	month