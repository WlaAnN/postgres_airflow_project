SELECT
	CASE 
		WHEN COUNT(1) > 0
			THEN 1
		ELSE 0
	END AS errors
FROM fact_transactions tra
JOIN dim_tariffs tar
ON tra.tariff_number = tar.tariff_number
JOIN dim_promocodes pro
ON pro.promocode_number = tra.promocode_number
JOIN dim_dates dat
ON dat.date_number = tra.date_number
WHERE dat.full_date NOT BETWEEN GREATEST(tar.tariff_valid_from, COALESCE(pro.promocode_valid_from, '0001-01-01')) AND LEAST(COALESCE(tar.tariff_valid_to, '9999-12-31'), COALESCE(pro.promocode_valid_to, '9999-12-31'))
