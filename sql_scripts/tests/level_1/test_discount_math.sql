SELECT
	CASE 
		WHEN COUNT(1) > 0
			THEN 1
		ELSE 0 
	END AS errors
FROM fact_transactions tra
JOIN dim_tariffs tar
ON tar.tariff_number = tra.tariff_number
LEFT JOIN dim_promocodes pro
ON pro.promocode_number = tra.promocode_number
WHERE tra.full_price != tar.tariff_price
	OR (tra.promocode_number IS NULL AND net_price != tar.tariff_price)
	OR (tra.promocode_number IS NOT NULL AND pro.promocode_type = 'amount' 
		AND tra.discount_amount != pro.promocode_sale 
		AND tar.tariff_price > pro.promocode_sale)
	OR (pro.promocode_type = 'amount' AND tar.tariff_price < pro.promocode_sale
		AND tra.discount_amount != tar.tariff_price - 1)
	OR (tra.promocode_number IS NOT NULL AND pro.promocode_type = 'percent' 
		AND tra.discount_amount != tar.tariff_price * pro.promocode_sale::NUMERIC(10, 2) / 100)

