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
        EXTRACT(MONTH FROM publish_time::timestamp) AS month_num,
        CASE EXTRACT(MONTH FROM publish_time::timestamp)
            WHEN 1 THEN 'Enero'
            WHEN 2 THEN 'Febrero'
            WHEN 3 THEN 'Marzo'
            WHEN 4 THEN 'Abril'
            WHEN 5 THEN 'Mayo'
            WHEN 6 THEN 'Junio'
            WHEN 11 THEN 'Noviembre'
            WHEN 12 THEN 'Diciembre'
        END AS publish_month,
        views,
        (likes + comment_count)::float / NULLIF(views, 0) * 100 AS engagement_rate,
        likes::float / NULLIF(likes + dislikes, 0) * 100 AS like_ratio
    FROM last_observation
)
SELECT 
    publish_month,
    COUNT(video_id) AS total_videos,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY views) AS median_views,
    AVG(engagement_rate) AS avg_engagement,
    AVG(like_ratio) AS avg_like_ratio
FROM metrics
GROUP BY month_num, publish_month
ORDER BY month_num;
