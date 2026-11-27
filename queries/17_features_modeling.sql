SELECT 
    v.video_id,
    v.channel_title,
    v.category_id::text as category_name,
    v.publish_time,
    MIN(v.trending_date) AS first_trending_date,
    (ARRAY_AGG(v.views ORDER BY v.trending_date ASC))[1] AS views_first,
    (ARRAY_AGG(v.likes ORDER BY v.trending_date ASC))[1] AS likes_first,
    (ARRAY_AGG(v.comment_count ORDER BY v.trending_date ASC))[1] AS comments_first,
    COUNT(DISTINCT v.trending_date) AS days_in_trending,
    MAX(v.views) AS views_max,
    (MIN(v.trending_date)::date - v.publish_time::date) AS days_to_trending
FROM test.us_videos_daily v
WHERE v.title <> 'Deleted video' 
  AND v.video_error_or_removed = FALSE
  AND (v.trending_date::date - v.publish_time::date) >= 0
GROUP BY 
    v.video_id, 
    v.channel_title, 
    v.category_id, 
    v.publish_time
HAVING COUNT(DISTINCT v.channel_title) = 1 
   AND COUNT(DISTINCT v.category_id) = 1;