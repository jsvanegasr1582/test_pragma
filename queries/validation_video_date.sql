SELECT *
FROM test.us_videos
WHERE (video_id, trending_date) IN (
    SELECT video_id, trending_date
    FROM test.us_videos
    GROUP BY video_id, trending_date
    HAVING COUNT(*) > 1
)
ORDER BY video_id, trending_date;