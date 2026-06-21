SELECT
	CASE 
		WHEN COUNT(1) > 0
			THEN 1
		ELSE 0
	END AS errors
FROM fact_transactions
WHERE tariff_number IS NULL 
	OR (promocode_number IS NULL AND discount_amount != 0) 
	OR user_number IS NULL 
	OR date_number IS NULL
	
