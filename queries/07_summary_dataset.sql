
WITH dataset_overview AS (
    SELECT
        COUNT(*) AS total_records,
        COUNT(DISTINCT video_id) AS unique_videos,
        COUNT(DISTINCT channel_title) AS unique_channels,
        COUNT(DISTINCT category_id) AS unique_categories,
        MIN(trending_date) AS first_trending_date,
        MAX(trending_date) AS last_trending_date,
        MIN(publish_time)::date AS earliest_publish_datetime,
        MAX(publish_time)::date AS latest_publish_datetime,
        COUNT(*) FILTER (
            WHERE comments_disabled IS TRUE
        ) AS records_comments_disabled,

        COUNT(*) FILTER (
            WHERE ratings_disabled IS TRUE
        ) AS records_ratings_disabled,

        COUNT(*) FILTER (
            WHERE video_error_or_removed IS TRUE
        ) AS records_with_video_errors
    FROM test.us_videos_daily
),
last_data AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY video_id
            ORDER BY trending_date DESC
        ) AS rn
    FROM test.us_videos_daily
),
video_metrics AS (
    SELECT
        SUM(views) AS total_views,
        SUM(likes) AS total_likes,
        SUM(dislikes) AS total_dislikes,
        SUM(comment_count) AS total_comments
    FROM last_data
    WHERE rn = 1
)
SELECT *
FROM dataset_overview
CROSS JOIN video_metrics;

