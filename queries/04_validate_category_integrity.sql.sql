SELECT
    v.category_id,
    COUNT(*) FILTER (
        WHERE c.id IS NULL
    ) AS affected_records,
    COUNT(*) FILTER (
        WHERE c.assignable = FALSE
    ) AS non_assignable_records
FROM test.us_videos_daily v
LEFT JOIN test.us_category_id c
    ON v.category_id = c.id
GROUP BY v.category_id
ORDER BY v.category_id;