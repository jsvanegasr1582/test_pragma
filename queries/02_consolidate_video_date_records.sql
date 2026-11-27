WITH channel_dominance AS (
    SELECT 
        video_id,
        MAX(freq::float / total_freq) AS max_channel_share,
        COUNT(DISTINCT lower_channel) AS distinct_channels
    FROM (
        SELECT 
            video_id,
            LOWER(channel_title) AS lower_channel,
            COUNT(*) AS freq,
            SUM(COUNT(*)) OVER (PARTITION BY video_id) AS total_freq
        FROM test.us_videos
        GROUP BY video_id, LOWER(channel_title)
    ) t
    GROUP BY video_id
),
category_dominance AS (
    SELECT 
        video_id,
        MAX(freq::float / total_freq) AS max_category_share,
        COUNT(DISTINCT category_id) AS distinct_categories
    FROM (
        SELECT 
            video_id,
            category_id,
            COUNT(*) AS freq,
            SUM(COUNT(*)) OVER (PARTITION BY video_id) AS total_freq
        FROM test.us_videos
        GROUP BY video_id, category_id
    ) t
    GROUP BY video_id
),
corrupt_videos AS (
    SELECT DISTINCT ch.video_id
    FROM channel_dominance ch
    JOIN category_dominance ca ON ch.video_id = ca.video_id
    WHERE ch.distinct_channels >= 3
       OR (ch.distinct_channels = 2 AND ca.distinct_categories > 1 AND ch.max_channel_share <= 0.5)
),
modal_channel AS (
    SELECT video_id, channel_title,
        ROW_NUMBER() OVER (
            PARTITION BY video_id 
            ORDER BY COUNT(*) DESC, channel_title ASC
        ) AS rn_ch
    FROM test.us_videos
    GROUP BY video_id, channel_title
),
clean_channel AS (
    SELECT video_id, channel_title AS clean_channel_title
    FROM modal_channel WHERE rn_ch = 1
),
modal_category AS (
    SELECT video_id, category_id,
        ROW_NUMBER() OVER (
            PARTITION BY video_id 
            ORDER BY COUNT(*) DESC, category_id ASC
        ) AS rn_cat
    FROM test.us_videos
    GROUP BY video_id, category_id
),
clean_category AS (
    SELECT video_id, category_id AS clean_category_id
    FROM modal_category WHERE rn_cat = 1
),
min_publish AS (
    SELECT video_id, MIN(publish_time) AS clean_publish_time
    FROM test.us_videos
    GROUP BY video_id
),
ranked_data AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY video_id, trending_date 
            ORDER BY views DESC, likes DESC, comment_count DESC, dislikes DESC
        ) AS rn
    FROM test.us_videos
    WHERE video_id NOT IN (SELECT video_id FROM corrupt_videos)
)
SELECT 
    r.video_id, 
    r.trending_date, 
    r.title, 
    ch.clean_channel_title AS channel_title, 
    c.clean_category_id AS category_id, 
    m.clean_publish_time AS publish_time, 
    r.tags, 
    r.views, 
    r.likes, 
    r.dislikes, 
    r.comment_count, 
    r.thumbnail_link, 
    r.comments_disabled, 
    r.ratings_disabled, 
    r.video_error_or_removed, 
    r.description
FROM ranked_data r
JOIN min_publish m ON r.video_id = m.video_id
JOIN clean_channel ch ON r.video_id = ch.video_id
JOIN clean_category c ON r.video_id = c.video_id
WHERE r.rn = 1;