SELECT
	CASE 
		WHEN SUM(total_revenue) != (SELECT SUM(transaction_net_price) FROM v_data_mart)
			THEN 1
		ELSE 0
	END AS errors
FROM v_by_year_mart