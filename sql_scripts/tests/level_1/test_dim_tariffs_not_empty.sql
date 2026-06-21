SELECT
	CASE 
		WHEN COUNT(1) = 0
			THEN 1
		ELSE 0
	END AS errors
FROM dim_tariffs