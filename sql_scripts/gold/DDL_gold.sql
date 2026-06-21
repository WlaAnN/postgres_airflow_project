DROP VIEW IF EXISTS v_by_tariff_mart CASCADE;
DROP VIEW IF EXISTS v_by_promocode_mart CASCADE;
DROP VIEW IF EXISTS v_by_month_mart CASCADE;
DROP VIEW IF EXISTS v_by_year_mart CASCADE;
DROP VIEW IF EXISTS v_by_quarter_mart CASCADE;
DROP VIEW IF EXISTS v_by_week_mart CASCADE;
DROP VIEW IF EXISTS v_by_day_mart CASCADE;
DROP VIEW IF EXISTS v_summary_mart CASCADE;
DROP VIEW IF EXISTS v_data_mart CASCADE;

CREATE VIEW v_data_mart AS(
	SELECT
	tra.net_price 					AS transaction_net_price,
	tra.full_price 					AS transaction_full_price,
	tra.discount_amount				AS transaction_discount_amount,
	use.user_number,
	use.create_date 				AS user_create_date,
	use.gender 						AS user_gender,
	use.is_active 					AS user_is_active,
	tar.tariff_version,
	tar.tariff_name,
	tar.tariff_duration_in_days,
	(pro.promocode_number IS NOT NULL)	AS promocode_is_used,
	pro.promocode_version,
	pro.promocode_code,
	pro.promocode_sale,
	pro.promocode_type,
	dat.full_date 					AS date_full,
	dat.date_year,
	dat.date_quarter,
	dat.date_month_name,
	dat.week_number 				AS date_week_number,
	dat.date_day,
	TO_CHAR(dat.full_date, 'Day') 	AS date_day_of_the_week,
	dat.is_weekend 					AS date_is_weekend,
	dat.is_holiday 					AS date_is_holiday
FROM fact_transactions tra
JOIN dim_dates dat
ON dat.date_number = tra.date_number
JOIN (
		SELECT
			tariff_number,
			tariff_name,
			tariff_duration_in_days,
			ROW_NUMBER() OVER(
				PARTITION BY tariff_name
				ORDER BY tariff_valid_from
			) 						AS tariff_version
		FROM dim_tariffs
	) 								AS tar
ON tar.tariff_number = tra.tariff_number
JOIN dim_users use
ON use.user_number = tra.user_number
LEFT JOIN (
		SELECT
			promocode_number,
			promocode_code,
			promocode_sale,
			promocode_type,	
			ROW_NUMBER() OVER(
				PARTITION BY promocode_code
				ORDER BY promocode_valid_from
			) 						AS promocode_version
		FROM dim_promocodes
	) 								AS pro
ON pro.promocode_number = tra.promocode_number
);

CREATE VIEW v_summary_mart AS(
SELECT
CASE
	WHEN promocode_is_used THEN 'with_promo'
	ELSE 'no_promo'
END AS promo_usage,
AVG(transaction_net_price) AS average_net_price,
SUM(transaction_net_price) AS total_revenue,
COUNT(1) AS amount,
COUNT(1)::NUMERIC(10, 2) / NULLIF((SELECT COUNT(1) FROM v_data_mart), 0) AS percentage,
SUM(transaction_discount_amount) total_discount
FROM v_data_mart
GROUP BY
	CASE
		WHEN promocode_is_used THEN 'with_promo'
		ELSE 'no_promo'
	END 
);
	
CREATE VIEW v_by_month_mart AS(
SELECT
	date_year,
	date_month_name,
	COUNT(transaction_net_price) AS transactions_amount,
	SUM(transaction_net_price) AS total_revenue,
	ROUND(AVG(transaction_net_price), 3) AS average_sale,
	ROUND((COUNT(1) FILTER(WHERE promocode_is_used) / COUNT(1)::NUMERIC(10, 2)) * 100, 3) AS transactions_with_promo_percentage
FROM v_data_mart
GROUP BY date_year, date_month_name
ORDER BY date_year, TO_DATE(v_data_mart.date_month_name, 'Month')
);

CREATE VIEW v_by_year_mart AS(
SELECT
	date_year,
	COUNT(1) AS total_amount,
	SUM(transaction_net_price) AS total_revenue,
	ROUND(AVG(transaction_net_price), 3) AS average_price,
	CASE 
		WHEN COUNT(1) > 0 
			THEN ROUND(COUNT(1) FILTER(WHERE promocode_is_used) / COUNT(1)::NUMERIC(10,2) * 100, 3) 
		ELSE 0
	END AS transactions_with_promo_percentage
FROM v_data_mart 
GROUP BY date_year
ORDER BY date_year
);

CREATE VIEW v_by_quarter_mart AS(
SELECT
	date_year,
	date_quarter,
	COUNT(1) AS total_amount,
	SUM(transaction_net_price) AS total_revenue,
	ROUND(AVG(transaction_net_price), 3) AS average_price,
	CASE 
		WHEN COUNT(1) > 0 
			THEN ROUND(COUNT(1) FILTER(WHERE promocode_is_used) / COUNT(1)::NUMERIC(10,2), 3) 
		ELSE 0
	END AS transactions_with_promo_percentage
FROM v_data_mart
GROUP BY date_year, date_quarter
ORDER BY date_year, date_quarter
);

CREATE VIEW v_by_week_mart AS(
SELECT
	date_year,
	date_week_number,
	COUNT(1) AS total_amount,
	SUM(transaction_net_price) AS total_revenue,
	ROUND(AVG(transaction_net_price), 3) AS average_price,
	CASE 
		WHEN COUNT(1) > 0 
			THEN ROUND(COUNT(1) FILTER(WHERE promocode_is_used) / COUNT(1)::NUMERIC(10,2), 3)
		ELSE 0
	END AS transactions_with_promo_percentage
FROM v_data_mart
GROUP BY date_year, date_week_number
ORDER BY date_year, date_week_number
);

CREATE VIEW v_by_day_mart AS(
SELECT
	date_year,
	date_month_name,
	date_day,
	COUNT(1) AS total_amount,
	SUM(transaction_net_price) AS total_revenue,
	ROUND(AVG(transaction_net_price), 3) AS average_price,
	CASE
		WHEN COUNT(1) > 0
			THEN ROUND(COUNT(1) FILTER(WHERE promocode_is_used) / COUNT(1)::NUMERIC(10,2), 3) 
		ELSE 0
	END AS transactions_with_promo_percentage
FROM v_data_mart
GROUP BY date_year, date_month_name, date_day
ORDER BY date_year, TO_DATE(v_data_mart.date_month_name, 'Month'), date_day
);

CREATE VIEW v_by_tariff_mart AS(
WITH cte_pre AS(
	SELECT
		user_number,
		tariff_name,
		tariff_version,
		transaction_net_price,
		DENSE_RANK() OVER (
				PARTITION BY tariff_name, 
							tariff_version, 
							user_number 
				ORDER BY date_full) AS user_repeat
	FROM v_data_mart
	ORDER BY user_number
)
SELECT
	tariff_name,
	tariff_version,
	SUM(transaction_net_price) AS total_revenue,
	COUNT(transaction_net_price) AS transactions_amount,
	COUNT(user_number) FILTER (WHERE user_repeat = 1) AS unique_users_amount
FROM cte_pre
GROUP BY tariff_name, tariff_version
);

CREATE VIEW v_by_promocode_mart AS(
WITH cte_pre AS(
	SELECT
		user_number,
		promocode_code,
		promocode_version,
		transaction_net_price,
		transaction_full_price,
		transaction_discount_amount,
		promocode_is_used,
		DENSE_RANK() OVER(PARTITION BY promocode_code, promocode_version, user_number ORDER BY date_full) AS user_repeat
	FROM v_data_mart
	WHERE promocode_is_used
)
SELECT
	promocode_code,
	promocode_version,
	SUM(transaction_net_price) AS total_revenue,
	SUM(transaction_discount_amount) AS total_discount,
	CASE 
		WHEN SUM(transaction_full_price) > 0
			THEN SUM(transaction_discount_amount) / SUM(transaction_full_price) * 100
		ELSE 0
	END AS discount_percentage,
	COUNT(1) AS usage_amount,
	COUNT(1) FILTER(WHERE user_repeat = 1) AS unique_users
FROM cte_pre
GROUP BY promocode_code, promocode_version
);


