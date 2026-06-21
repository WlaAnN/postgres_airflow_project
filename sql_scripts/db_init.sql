DROP TABLE IF EXISTS stg_dim_users;
CREATE TABLE stg_dim_users(
	source_user_id INT,
	first_name VARCHAR(50),
	last_name VARCHAR(50),
	birth_date DATE,
	gender VARCHAR(10),
	create_date DATE
);

	
DROP TABLE IF EXISTS stg_dim_tariffs;
CREATE TABLE stg_dim_tariffs(
	tariff_name VARCHAR(50),
	tariff_price INT,
	tariff_duration_in_days INT,
	tariff_valid_from DATE
);


DROP TABLE IF EXISTS stg_dim_promocodes;
CREATE TABLE stg_dim_promocodes(
	promocode_code VARCHAR(50),
	promocode_sale NUMERIC(10, 2),
	promocode_type VARCHAR(10),
	promocode_valid_from DATE,
	promocode_valid_to DATE
);


DROP TABLE IF EXISTS stg_fact_transactions;
CREATE TABLE stg_fact_transactions(
	source_user_id INT,
	tariff_name VARCHAR(50),
	promocode_code VARCHAR(50),
	transaction_date DATE,
	full_price NUMERIC(10, 2),
	discount_amount NUMERIC(10, 2),
	net_price NUMERIC(10, 2)
);

DROP TABLE IF EXISTS elt_log;
CREATE TABLE elt_log(
	log_id SERIAL,
	table_name VARCHAR(50) NOT NULL,
	rows_amount INT NOT NULL,
	load_date TIMESTAMP NOT NULL DEFAULT NOW(),
	data_from DATE,
	data_to DATE,
	status VARCHAR(30) DEFAULT 'SUCCESS',
	error_message VARCHAR (100) DEFAULT NULL
);

DROP VIEW  IF EXISTS v_data_mart CASCADE;
DROP TABLE IF EXISTS fact_transactions;
DROP TABLE IF EXISTS dim_users;
DROP TABLE IF EXISTS dim_tariffs;
DROP TABLE IF EXISTS dim_promocodes;
DROP TABLE IF EXISTS dim_dates;

CREATE TABLE dim_users(
	user_number SERIAL PRIMARY KEY,
	source_user_id INT UNIQUE,
	first_name VARCHAR(50) NOT NULL,
	last_name VARCHAR(50) NOT NULL,
	birth_date DATE CHECK (birth_date <= NOW()),
	gender VARCHAR(1) CHECK(gender IN ('F', 'M')),
	create_date DATE NOT NULL CHECK (create_date <= NOW()),
	is_active BOOL NOT NULL
);

CREATE TABLE dim_tariffs(
	tariff_number SERIAL PRIMARY KEY,
	tariff_name VARCHAR(50) NOT NULL,
	tariff_price NUMERIC(10, 2) NOT NULL CHECK(tariff_price > 0),
	tariff_duration_in_days INT NOT NULL CHECK(tariff_duration_in_days > 0),
	tariff_valid_from DATE NOT NULL,
	tariff_valid_to DATE DEFAULT NULL
);

CREATE TABLE dim_promocodes(
	promocode_number SERIAL PRIMARY KEY,
	promocode_code VARCHAR(100) NOT NULL,
	promocode_sale NUMERIC(10,2) NOT NULL,
	promocode_type VARCHAR(20) NOT NULL CHECK (promocode_type IN ('percent', 'amount')),
	promocode_valid_from DATE NOT NULL,
	promocode_valid_to DATE DEFAULT NULL,
	CHECK (
		promocode_valid_to IS NULL 
		OR promocode_valid_to > promocode_valid_from
	)
);

CREATE TABLE dim_dates(
	date_number SERIAL PRIMARY KEY,
	full_date DATE UNIQUE NOT NULL,
	date_year INT NOT NULL,
	date_quarter INT NOT NULL,
	date_month INT NOT NULL,
	date_month_name VARCHAR(20) NOT NULL,
	week_number INT NOT NULL CHECK (week_number >= 1 AND week_number <= 53),
	date_day INT NOT NULL,
	day_of_week INT CHECK (day_of_week <= 7 AND day_of_week >= 1) NOT NULL,
	is_weekend BOOL NOT NULL,
	is_holiday BOOL NOT NULL
);

CREATE TABLE fact_transactions(
	transaction_number SERIAL PRIMARY KEY,
	user_number INT NOT NULL,
	tariff_number INT NOT NULL,
	promocode_number INT,
	date_number INT NOT NULL,
	net_price NUMERIC(10, 2) NOT NULL,
	full_price NUMERIC(10, 2) NOT NULL,
	discount_amount NUMERIC(10, 2) NOT NULL,
    CONSTRAINT check_net_price 
        CHECK(net_price = full_price - discount_amount),
	CONSTRAINT fk_fact_user
		FOREIGN KEY (user_number)
		REFERENCES dim_users (user_number)
		ON UPDATE RESTRICT
		ON DELETE RESTRICT,
	CONSTRAINT fk_fact_tariff
		FOREIGN KEY (tariff_number)
	 	REFERENCES dim_tariffs (tariff_number)
		ON UPDATE RESTRICT
		ON DELETE RESTRICT,
	CONSTRAINT fk_fact_promocode
		FOREIGN KEY (promocode_number)
		REFERENCES dim_promocodes (promocode_number)
		ON UPDATE RESTRICT
		ON DELETE RESTRICT,
	CONSTRAINT fk_fact_date
		FOREIGN KEY (date_number)
		REFERENCES dim_dates (date_number)
		ON UPDATE RESTRICT
		ON DELETE RESTRICT
);

CREATE INDEX idx_fact_users ON fact_transactions(user_number);
CREATE INDEX idx_fact_tariffs ON fact_transactions(tariff_number);
CREATE INDEX idx_fact_promocodes ON fact_transactions(promocode_number);
CREATE INDEX idx_fact_dates ON fact_transactions(date_number);

CREATE OR REPLACE VIEW v_data_mart AS(
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

CREATE OR REPLACE VIEW v_summary_mart AS(
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
	
CREATE OR REPLACE VIEW v_by_month_mart AS(
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

CREATE OR REPLACE VIEW v_by_year_mart AS(
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

CREATE OR REPLACE VIEW v_by_quarter AS(
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

CREATE OR REPLACE VIEW v_by_week_mart AS(
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

CREATE OR REPLACE VIEW v_by_day_mart AS(
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

CREATE OR REPLACE VIEW v_by_tariff_mart AS(
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

CREATE OR REPLACE VIEW v_by_promocode_mart AS(
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



