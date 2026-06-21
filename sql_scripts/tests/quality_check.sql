

SELECT
	MIN(net_price),
	MAX(net_price)
FROM fact_transactions;

--Результат: 1.00, 5399.00

----------------------------------
WITH cte_pre AS(
SELECT
	COUNT(*) AS total_amount,
	(SELECT 
		COUNT(*) 
	FROM fact_transactions
	WHERE promocode_number IS NOT NULL) with_promo
FROM fact_transactions
) 
SELECT
	total_amount,
	with_promo,
	total_amount - with_promo AS no_promo,
	CAST(with_promo AS NUMERIC) / total_amount * 100 AS percent_promo
FROM cte_pre

--Результат: 1000, 829, 171, 82.9

----------------------------------

SELECT
	COUNT(u.user_number)
FROM dim_users u
LEFT JOIN fact_transactions t
ON u.user_number = t.user_number
WHERE t.user_number IS NULL

--Результат: 4104



--Ожидаемый результат: >= 0, так как тариф может быть непопулярным или только что появится, существует вероятность при которой у тарифа будет 0 транзакций.

SELECT
	COUNT(d.tariff_number)
FROM dim_tariffs d
LEFT JOIN fact_transactions t
ON d.tariff_number = t.tariff_number
WHERE t.tariff_number IS NULL
--Результат : 0

---------------------------------

--Намного важнее эта проблема на целостность данных
--Ожидаемый результат: 0

SELECT
	COUNT(t.tariff_number) AS amount_of_not_used_tariffs
FROM fact_transactions t
LEFT JOIN dim_tariffs d
ON d.tariff_number = t.tariff_number
WHERE d.tariff_number IS NULL

--Результат: 0

--------------------------------

SELECT
	SUM(net_price) total_sales
FROM fact_transactions

--Результат: 1293969.50

---------------------------------

--Ожидаемый результат: 1293969.50

WITH cte_tariff_sales AS(
SELECT
	SUM(net_price) tariff_sales
FROM fact_transactions t
GROUP BY t.tariff_number
)

SELECT
	SUM(tariff_sales) total_tariff_sales
FROM cte_tariff_sales

--Результат: 1293969.50

--------------------------------------

--Ожидаемый результат: 1293969.50

WITH cte_month_sales AS (
SELECT
	SUM(t.net_price) month_sales,
	date_year, 
	date_month
FROM fact_transactions t
JOIN dim_dates d
ON d.date_number = t.date_number
GROUP BY date_year, date_month
)
SELECT
	SUM(month_sales) total_month_sales
FROM cte_month_sales

--Результат: 1293969.50

-----------------------------------



/*
====================================
data_marts_quality
====================================

*/
	
--Ожидаемый результат: 0
	
SELECT	
	COUNT(m.user_number) users_errors_in_mart
FROM v_data_mart m
LEFT JOIN dim_users u
ON m.user_number = u.user_number
WHERE u.user_number IS NULL

--Результат: 0

------------------------------------

--Ожидаемый результат: 0

SELECT	
	COUNT(1)
FROM v_data_mart
WHERE date_full > NOW() OR date_full < '1980-01-01'

--Результат: 0

------------------------------------

--Ожидаемый резульат: 0
SELECT	
	COUNT(1)
FROM v_data_mart 
WHERE user_create_date > NOW() OR user_create_date < '1980-01-01'

--Результат: 0

------------------------------------

SELECT
	*
FROM v_by_month_mart
------------------------------------

--Ожидаемый результат: True

SELECT	
	SUM(total_revenue) = (
							SELECT
								SUM(net_price)
							FROM fact_transactions
							) AS equal
FROM v_by_month_mart

--Результат: True

----------------------------------

SELECT
	SUM()











