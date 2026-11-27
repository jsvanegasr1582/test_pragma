WITH last_data AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY video_id
               ORDER BY trending_date DESC
           ) AS rn
    FROM test.us_videos_daily
)
SELECT  v.video_id, 
	    views
FROM last_data v
WHERE v.rn = 1


