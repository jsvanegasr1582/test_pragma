WITH last_data AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY video_id
            ORDER BY trending_date DESC
        ) AS rn
    FROM test.us_videos_daily
),
trending_stats AS (
    SELECT
        video_id,
        COUNT(DISTINCT trending_date) AS days_in_trending,
        MIN(trending_date) AS first_trending_date,
        MIN(views) AS initial_views
    FROM test.us_videos_daily
    GROUP BY video_id
),
video_metrics AS (
    SELECT
        v.video_id,
        c.title AS title_category,
        v.views,
        v.likes,
        v.dislikes,
        v.comment_count,
        s.days_in_trending,
        s.first_trending_date,
        s.initial_views,
        (v.likes + v.comment_count)::numeric
            / NULLIF(v.views, 0) * 100 AS engagement_rate,
        v.likes::numeric
            / NULLIF(v.likes + v.dislikes, 0) * 100 AS like_ratio
    FROM last_data v
    LEFT JOIN test.us_category_id c
        ON v.category_id = c.id
    LEFT JOIN trending_stats s
        ON v.video_id = s.video_id
    WHERE v.rn = 1
),
category_summary AS (
    SELECT
        title_category,
        COUNT(video_id) AS videos,
        percentile_cont(0.5) WITHIN GROUP (
            ORDER BY views::double precision
        ) AS median_views,
        percentile_cont(0.5) WITHIN GROUP (
            ORDER BY likes::double precision
        ) AS median_likes,
        percentile_cont(0.5) WITHIN GROUP (
            ORDER BY engagement_rate::double precision
        ) AS median_engagement_pct,
        percentile_cont(0.5) WITHIN GROUP (
            ORDER BY like_ratio::double precision
        ) AS median_like_ratio_pct,
        AVG(days_in_trending) AS avg_days_trending
    FROM video_metrics
    WHERE title_category IS NOT NULL
    GROUP BY title_category
    HAVING COUNT(video_id) >= 20
)
SELECT
    title_category,
    videos,
    median_views,
    median_likes,
    median_engagement_pct,
    median_like_ratio_pct,
    avg_days_trending
FROM category_summary
ORDER BY videos DESC;
