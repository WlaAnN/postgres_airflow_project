SELECT
	CASE 
		WHEN COUNT(1) > 0
			THEN 1
		ELSE 0
	END AS errors
FROM v_data_mart
WHERE promocode_is_used AND promocode_code IS NULL