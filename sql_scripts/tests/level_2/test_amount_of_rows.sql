SELECT
	CASE 
		WHEN COUNT(1) != (SELECT COUNT(1) FROM fact_transactions)
			THEN 1
		ELSE 0
	END AS errors
FROM v_data_mart