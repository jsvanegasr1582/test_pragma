SELECT
    video_id,
    publish_time,
    trending_date
FROM test.us_videos_daily
WHERE publish_time::DATE > trending_date
ORDER BY trending_date;