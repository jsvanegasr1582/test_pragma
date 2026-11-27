WITH last_observation AS (
    SELECT DISTINCT ON (video_id)
        video_id,
        publish_time,
        views,
        likes,
        dislikes,
        comment_count
    FROM test.us_videos_daily
    WHERE publish_time::DATE >= '2017-11-01' 
      AND publish_time::DATE <= '2018-06-30'
    ORDER BY video_id, trending_date DESC
),
metrics AS (
    SELECT 
        video_id,
        EXTRACT(ISODOW FROM publish_time::timestamp) AS dow_num,
        CASE EXTRACT(ISODOW FROM publish_time::timestamp)
            WHEN 1 THEN 'Lunes'
            WHEN 2 THEN 'Martes'
            WHEN 3 THEN 'Miércoles'
            WHEN 4 THEN 'Jueves'
            WHEN 5 THEN 'Viernes'
            WHEN 6 THEN 'Sábado'
            WHEN 7 THEN 'Domingo'
        END AS publish_weekday,
        views,
        (likes + comment_count)::float / NULLIF(views, 0) * 100 AS engagement_rate,
        likes::float / NULLIF(likes + dislikes, 0) * 100 AS like_ratio
    FROM last_observation
)
SELECT 
    publish_weekday,
    COUNT(video_id) AS total_videos,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY views) AS median_views,
    AVG(engagement_rate) AS avg_engagement,
    AVG(like_ratio) AS avg_like_ratio
FROM metrics
GROUP BY dow_num, publish_weekday
ORDER BY dow_num;
