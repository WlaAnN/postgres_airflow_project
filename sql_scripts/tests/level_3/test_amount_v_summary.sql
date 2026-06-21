SELECT
	CASE
		WHEN SUM(amount) != (SELECT	COUNT(1) FROM v_data_mart)
			THEN 1
		ELSE 0
	END AS errors
FROM v_summary_mart

