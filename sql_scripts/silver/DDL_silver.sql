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



