SELECT
    COUNT(*) FILTER (WHERE views < 0) AS negative_views,
    COUNT(*) FILTER (WHERE likes < 0) AS negative_likes,
    COUNT(*) FILTER (WHERE dislikes < 0) AS negative_dislikes,
    COUNT(*) FILTER (WHERE comment_count < 0) AS negative_comments
FROM test.us_videos_daily;