SELECT
    video_id,
    trending_date,
    COUNT(*) AS record_count
FROM test.us_videos_daily
GROUP BY
    video_id,
    trending_date
HAVING COUNT(*) > 1;