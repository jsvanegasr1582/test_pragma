WITH last_observation AS (
    SELECT DISTINCT ON (video_id)
        video_id,
        title,
        category_id,
        publish_time,
        tags,
        views,
        likes,
        dislikes,
        comment_count
    FROM test.us_videos_daily
    ORDER BY video_id, trending_date DESC
),
trending_stats AS (
    SELECT 
        video_id,
        COUNT(DISTINCT trending_date) AS days_in_trending,
        MIN(trending_date) AS first_trending_date
    FROM test.us_videos_daily
    GROUP BY video_id
)
SELECT 
    l.video_id,
    l.title,
    l.category_id,
    l.publish_time,
    l.tags,
    l.views,
    l.likes,
    l.dislikes,
    l.comment_count,
    t.days_in_trending,
    EXTRACT(EPOCH FROM (t.first_trending_date::timestamp - l.publish_time::timestamp)) / 86400.0 AS days_to_trending
FROM last_observation l
JOIN trending_stats t ON l.video_id = t.video_id;