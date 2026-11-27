WITH last_data AS (
    SELECT DISTINCT ON (video_id)
        *
    FROM test.us_videos_daily
    ORDER BY video_id, trending_date DESC
),
trending_stats AS (
    SELECT
        video_id,
        MIN(trending_date) AS first_trending_date
    FROM test.us_videos_daily
    GROUP BY video_id
)
SELECT
    v.*,
    c.id,
    c.title AS title_category,
    c.assignable,
    s.first_trending_date,
    CASE
        WHEN s.first_trending_date IS NULL OR v.publish_time IS NULL THEN NULL
        ELSE GREATEST(
            s.first_trending_date::date - v.publish_time::date,
            0
        )
    END AS days_to_trending,
    EXTRACT(HOUR FROM v.publish_time::timestamp)::integer AS publish_hour,
    CASE EXTRACT(ISODOW FROM v.publish_time::timestamp)
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
        WHEN 7 THEN 'Sunday'
    END AS publish_dow
FROM last_data v
LEFT JOIN test.us_category_id c
    ON v.category_id = c.id
LEFT JOIN trending_stats s
    ON v.video_id = s.video_id;
