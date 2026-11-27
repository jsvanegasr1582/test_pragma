WITH last_data AS (
    SELECT DISTINCT ON (video_id)
        video_id,
        publish_time
    FROM test.us_videos_daily
    ORDER BY video_id, trending_date DESC
),
first_trending AS (
    SELECT
        video_id,
        MIN(trending_date) AS first_trending_date
    FROM test.us_videos_daily
    GROUP BY video_id
)
SELECT
    v.video_id,
    v.publish_time,
    f.first_trending_date,
    EXTRACT(ISODOW FROM v.publish_time::timestamp) AS dow_num,
    CASE EXTRACT(ISODOW FROM v.publish_time::timestamp)
        WHEN 1 THEN 'Lunes'
        WHEN 2 THEN 'Martes'
        WHEN 3 THEN 'Miércoles'
        WHEN 4 THEN 'Jueves'
        WHEN 5 THEN 'Viernes'
        WHEN 6 THEN 'Sábado'
        WHEN 7 THEN 'Domingo'
    END AS publish_weekday,
    EXTRACT(EPOCH FROM (f.first_trending_date::timestamp - v.publish_time::timestamp)) / 86400.0 AS days_to_trending
FROM last_data v
JOIN first_trending f ON v.video_id = f.video_id
