SELECT
	CASE
		WHEN COUNT(1) = 0
			THEN 1	
		ELSE 0
	END AS error
FROM dim_users