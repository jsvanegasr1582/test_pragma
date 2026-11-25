SELECT  video_id,
        trending_date,
        title,
        channel_title,
        category_id,
        publish_time,
        tags,
        views,
        likes,
        dislikes,
        comment_count,
        thumbnail_link,
        comments_disabled,
        ratings_disabled,
        video_error_or_removed
        description
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY video_id, trending_date
               ORDER BY views DESC,
                        likes DESC,
                        comment_count DESC,
                        dislikes DESC
           ) AS rn
    FROM test.us_videos
) ranked
WHERE rn = 1;