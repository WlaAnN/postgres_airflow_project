SELECT
	CASE 
		WHEN COUNT(1) > 0
			THEN 1
		ELSE 0
	END AS errors
FROM fact_transactions
WHERE net_price != full_price - discount_amount