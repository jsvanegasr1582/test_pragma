
WITH duplicate_records AS (
    SELECT video_id, trending_date
    FROM test.us_videos
    GROUP BY video_id, trending_date
    HAVING COUNT(*) > 1
),
inconsistent_publish_dates AS (
    SELECT video_id
    FROM test.us_videos
    GROUP BY video_id
    HAVING COUNT(DISTINCT publish_time) > 1
)
SELECT 
    v.*,
    CASE 
        WHEN d.video_id IS NOT NULL AND i.video_id IS NOT NULL THEN 'Ambos errores'
        WHEN d.video_id IS NOT NULL THEN 'Duplicado en mismo día'
        WHEN i.video_id IS NOT NULL THEN 'Inconsistencia en fecha de publicación'
    END AS tipo_error
FROM test.us_videos v
LEFT JOIN duplicate_records d 
    ON v.video_id = d.video_id AND v.trending_date = d.trending_date
LEFT JOIN inconsistent_publish_dates i 
    ON v.video_id = i.video_id
WHERE d.video_id IS NOT NULL OR i.video_id IS NOT NULL
ORDER BY v.video_id, v.trending_date;





