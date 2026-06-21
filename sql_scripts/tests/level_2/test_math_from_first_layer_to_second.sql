SELECT
	CASE 
		WHEN SUM(transaction_net_price) != (SELECT SUM(net_price) FROM fact_transactions)
			THEN 1
		ELSE 0
	END AS errors
FROM v_data_mart