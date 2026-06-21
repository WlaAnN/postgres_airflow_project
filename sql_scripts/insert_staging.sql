INSERT INTO stg_dim_users(
	source_user_id,
	first_name,
	last_name,
	birth_date,
	gender,
	create_date
)
SELECT
	n AS source_user_id,
	CASE 
		WHEN random() < 0.1 THEN 'Oleg'
		WHEN random() < 0.2 THEN 'Marat'
		WHEN random() < 0.3 THEN 'Lisa'
		WHEN random() < 0.4 THEN 'Nikita'
		WHEN random() < 0.5 THEN 'Mariya'
		WHEN random() < 0.6 THEN 'Vladislav'
		WHEN random() < 0.7 THEN 'Dmitriy'
		WHEN random() < 0.8 THEN 'Anastasiya'
		WHEN random() < 0.9 THEN 'Eva'
		ELSE 'Anya' 
	END AS first_name,
	CASE 
		WHEN random() < 0.1 THEN 'Esipov(a)'
		WHEN random() < 0.2 THEN 'Savkov'
		WHEN random() < 0.3 THEN 'Moiseev(a)'
		WHEN random() < 0.4 THEN 'Eliseev(a)'
		WHEN random() < 0.5 THEN 'Cheshev(a)'
		WHEN random() < 0.6 THEN 'Karmanov(a)'
		WHEN random() < 0.7 THEN 'Mubalu'
		WHEN random() < 0.8 THEN 'Deblik'
		WHEN random() < 0.9 THEN 'Kalabishka'
		ELSE 'Volkhonskiy(aya)' 
	END AS last_name,
	'2000-04-23'::DATE + (random() * 1000)::INT AS birth_date,
	CASE 
		WHEN random() < 0.25 THEN 'Male'
		WHEN random() < 0.5 THEN 'M'
		WHEN random() < 0.75 THEN 'Female'
		ELSE 'F'
	END AS gender,
	NOW()::DATE
FROM generate_series((SELECT COALESCE(MAX(user_number), 0) FROM dim_users) + 1
					, (SELECT COALESCE(MAX(user_number), 0) FROM dim_users) + 501) AS gs(n);

INSERT INTO stg_dim_tariffs(
	tariff_name,
	tariff_price,
	tariff_duration_in_days,
	tariff_valid_from
)
VALUES
('Long Ultimate+', 5699, 365, NOW()::DATE),
('Basic', 209, 30, NOW()::DATE),
('Basic', 209, 30, NOW()::DATE + 100),
('Basic', 199, 30, '2025-01-01');

INSERT INTO stg_dim_promocodes(
	promocode_code,
	promocode_sale,
	promocode_type,
	promocode_valid_from,
	promocode_valid_to
)
VALUES
('NEWYEARSALE30', 30, 'percent', '2025-12-24', '2025-12-31'),
('EASYSTART', 10, 'percent', '2025-01-01', NULL),
('NEWYEARSALE30', 25, 'percent', NOW()::DATE, NOW()::DATE + 30),
('SUMMERSALE15', 15, 'percent', NOW()::DATE, NULL);

INSERT INTO stg_fact_transactions(
	source_user_id,
	tariff_name,
	promocode_code,
	transaction_date,
	full_price,
	discount_amount,
	net_price
)
WITH cte_pre_transactions AS
(
SELECT
	CASE 
		WHEN random() < 0.95 THEN n
		ELSE n - 2
	END AS source_user_id,
	CASE 
		WHEN random() < 0.2 THEN 'Basic'
		WHEN random() < 0.4 THEN 'Trial'
		WHEN random() < 0.6 THEN 'Medium' 
		WHEN random() < 0.8 THEN 'Long Ultimate'
		ELSE 'Basic+'
	END AS tariff_name,
	CASE 
		WHEN random() < 0.2 THEN 'BLACKFRIDAY20'
		WHEN random() < 0.4 THEN 'EASYSTART'
		WHEN random() < 0.6 THEN 'NEWYEARSALE30'
		ELSE NULL
	END AS promocode_code
FROM generate_series((SELECT COALESCE(MAX(user_number), 0) FROM dim_users) + 1,
					 (SELECT COALESCE(MAX(user_number), 0) FROM dim_users) + 501) AS gs(n)
),
	
cte_pre2_transactions AS
(
SELECT
	source_user_id,
	tariff_name,
	promocode_code,
	CASE 
		WHEN tariff_name = 'Basic' THEN 199
		WHEN tariff_name = 'Trial' THEN 89
		WHEN tariff_name = 'Medium' THEN 299
		WHEN tariff_name = 'Long Ultimate' THEN 5399
		WHEN tariff_name = 'Basic+' THEN 249
		ELSE NULL
	END AS full_price
FROM cte_pre_transactions
)
SELECT	
	source_user_id,
	tariff_name,
	promocode_code,
	NOW()::DATE AS transaction_date,
	full_price,
	CASE 
		WHEN promocode_code = 'BLACKFRIDAY20' THEN full_price * ((100 - 80::DECIMAL)/100)
		WHEN promocode_code = 'EASYSTART' THEN full_price * ((100 - 90::DECIMAL)/100)
		WHEN promocode_code = 'NEWYEARSALE30' THEN full_price * ((100 - 70::DECIMAL)/100)
		WHEN promocode_code IS NULL THEN 0
		ELSE NULL
	END AS discount_amount,
	CASE 
		WHEN promocode_code = 'BLACKFRIDAY20' THEN full_price * ((100 - 20::DECIMAL)/100)
		WHEN promocode_code = 'EASYSTART' THEN full_price * ((100 - 10::DECIMAL)/100)
		WHEN promocode_code = 'NEWYEARSALE30' THEN full_price * ((100 - 30::DECIMAL)/100)
		WHEN promocode_code IS NULL THEN full_price
		ELSE NULL
	END AS net_price
FROM cte_pre2_transactions
