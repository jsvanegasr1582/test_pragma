WITH last_data AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY video_id
               ORDER BY trending_date DESC
           ) AS rn
    FROM test.us_videos_daily
)
SELECT
    c.title AS category,
    COUNT(*) AS total_videos,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM last_data v
JOIN test.us_category_id c
    ON v.category_id = c.id
WHERE v.rn = 1
GROUP BY c.title
ORDER BY total_videos DESC;

