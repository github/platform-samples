/* 
 * GitHub Actions Monthly Summary Report
 * -------------------------------------
 * This query generates a summary of GitHub Actions usage, grouped by month and year.
 * It includes:
 *   - Total compute hours (from job start to completion)
 *   - Average queue time in seconds (from queued to start)
 *   - Total number of jobs completed
 *
 * Assumptions:
 *   - Timestamps are in UTC and stored in columns: completed_at, started_at, queued_at, and created_at.
 *   - Jobs may not have a started_at timestamp, in which case queued_at or created_at is used as fallback.
 */

SELECT
    -- Extract the month of job completion
    MONTH(j.completed_at) AS month,

    -- Extract the year of job completion
    YEAR(j.completed_at) AS year,

    -- Calculate total compute hours by summing the duration of each job
    ROUND(
        SUM(
            UNIX_TIMESTAMP(j.completed_at) - UNIX_TIMESTAMP(
                COALESCE(j.started_at, j.queued_at, j.created_at)
            )
        ) / 3600
    ) AS compute_hours,

    -- Calculate average time (in seconds) that jobs spent in queue before starting
    ROUND(
        AVG(
            UNIX_TIMESTAMP(j.started_at) - UNIX_TIMESTAMP(j.queued_at)
        )
    ) AS seconds_queued,

    -- Count the number of jobs that completed in each month
    COUNT(j.completed_at) AS job_count

FROM
    github_enterprise.workflow_builds j

GROUP BY
    month,
    year

ORDER BY
    year,
    month;
