SELECT 
    'Duplicado mismo día' AS tipo_error,
    video_id,
    trending_date::text AS detalle,
    COUNT(*)::text AS valor
FROM test.us_videos_daily
GROUP BY video_id, trending_date
HAVING COUNT(*) > 1

UNION ALL

SELECT 
    'ID contaminado (canal/categoría)' AS tipo_error,
    video_id,
    'canales: ' || COUNT(DISTINCT channel_title) || ', categorías: ' || COUNT(DISTINCT category_id) AS detalle,
    NULL AS valor
FROM test.us_videos_daily
GROUP BY video_id
HAVING COUNT(DISTINCT channel_title) > 1 
    OR COUNT(DISTINCT category_id) > 1

UNION ALL

SELECT 
    'Fecha publicación inconsistente' AS tipo_error,
    video_id,
    COUNT(DISTINCT publish_time)::text || ' fechas distintas' AS detalle,
    NULL AS valor
FROM test.us_videos_daily
GROUP BY video_id
HAVING COUNT(DISTINCT publish_time) > 1;