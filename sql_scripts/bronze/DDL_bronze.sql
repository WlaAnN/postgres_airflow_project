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