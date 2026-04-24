WITH raw_logins AS (
    SELECT
        u.username,
        TO_TIMESTAMP(e.event_time/1000) AS date
    FROM public.event_entity e
    JOIN user_entity u ON e.user_id = u.id
    WHERE e.type = 'LOGIN'
      AND e.event_time/1000 >= 1719792000
      AND u.username LIKE '%@example.com'
),
first_login AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY username ORDER BY date) AS rn
    FROM raw_logins
),
new_users AS (
    SELECT
        EXTRACT(YEAR FROM date) AS year,
        EXTRACT(WEEK FROM date) AS week,
        COUNT(username) AS new_users_count
    FROM first_login
    WHERE rn = 1
    GROUP BY EXTRACT(YEAR FROM date), EXTRACT(WEEK FROM date)
),
weeks AS (
    SELECT generate_series(
        date_trunc('week', to_timestamp(1719792000)),
        date_trunc('week', now()),
        interval '1 week'
    ) AS week_start
),
logins_per_week AS (
    SELECT
        EXTRACT(YEAR FROM date) AS year,
        EXTRACT(WEEK FROM date) AS week,
        COUNT(username) AS count_login,
        COUNT(DISTINCT username) AS unique_count_login
    FROM raw_logins
    GROUP BY EXTRACT(YEAR FROM date), EXTRACT(WEEK FROM date)
)
SELECT
    EXTRACT(YEAR FROM w.week_start) AS year,
    EXTRACT(WEEK FROM w.week_start) AS week,
    COALESCE(l.count_login, 0) AS count_login,
    COALESCE(l.unique_count_login, 0) AS unique_count_login,
    COALESCE(n.new_users_count, 0) AS new_users_count
FROM weeks w
LEFT JOIN logins_per_week l
    ON EXTRACT(YEAR FROM w.week_start) = l.year
   AND EXTRACT(WEEK FROM w.week_start) = l.week
LEFT JOIN new_users n
    ON EXTRACT(YEAR FROM w.week_start) = n.year
   AND EXTRACT(WEEK FROM w.week_start) = n.week
ORDER BY w.week_start;