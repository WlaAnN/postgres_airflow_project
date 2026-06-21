WITH cte_names_list AS(
SELECT
	first_name,
	last_name
FROM (VALUES
	('Nikita', 'Romanov(a)'),
	('Manya', 'Eliseev(a)'),
	('Oleg', 'Tenishev(a)'), 
	('Robert', 'Poroshin(a)'), 
	('Karina', 'Imashev(a)'), 
	('Vladimir', 'Girik'), 
	('Artem', 'Podoliyako'), 
	('Evgeniy', 'Popov(a)'), 
	('Fedor', 'Cheshev(a)'), 
	('Aleksandr', 'Antonov'), 
	('Aleksey', 'Gareev(a)'), 
	('Yuriy', 'Moiseev(a)'), 
	('Valeiya', 'Kolesnikov(a)'),
	('Viktov', 'Coy'), 
	('Mura', 'Kanukov(a)')) AS first_last(first_name, last_name)
),
 cte_names AS
(
	SELECT
		f.first_name AS first_name,
		l.last_name AS last_name
	FROM generate_series(1, 5000) gs(n)
	JOIN LATERAL(
		SELECT
			first_name
		FROM cte_names_list
		ORDER BY random() + n * 0
		LIMIT 1
	) f
	ON TRUE
	JOIN LATERAL(
		SELECT
			last_name
		FROM cte_names_list
		ORDER BY random() + n * 0
		LIMIT 1
	) l
	ON TRUE
)
INSERT INTO dim_users(
	first_name,
	last_name,
	birth_date,
	gender,
	create_date,
	is_active
)
SELECT
	first_name,
	last_name,
	(CURRENT_DATE - INTERVAL '18 years' - 
		random() * INTERVAL '47 years')::DATE AS birth_date,
	CASE 
		WHEN random() < 0.5 THEN 'M'
		ELSE 'F'
	END AS gender,
	(DATE '2020-01-01' + random() * INTERVAL '5 years')::DATE AS create_date,
	CASE 
		WHEN random() < 0.7 THEN TRUE
		ELSE FALSE
	END AS is_active
FROM cte_names;

UPDATE dim_users
SET source_user_id = user_number;

INSERT INTO dim_tariffs(
	tariff_name,
	tariff_price,
	tariff_duration_in_days, 
	tariff_valid_from,
	tariff_valid_to
)
VALUES
	('Basic', 199, 30, '2025-01-01', NULL),
	('Basic+', 249, 30, '2025-01-01', '2025-06-01'),
	('Trial', 89, 7, '2025-01-01', NULL), 
	('Long Basic', 2199, 365, '2025-06-01', NULL),
	('Medium', 299, 30, '2025-01-01', NULL), 
	('Long Medium', 3299, 365, '2025-06-01', NULL),
	('Ultiamte', 499, 30, '2025-06-01', NULL), 
	('Long Ultimate', 5399, 365, '2025-06-01', NULL);

INSERT INTO dim_promocodes(
	promocode_code,
	promocode_sale,
	promocode_type, 
	promocode_valid_from,
	promocode_valid_to
)
VALUES 
	('NEWYEARSALE30', 30, 'percent', '2025-12-24', '2025-12-31'),
	('EASYSTART', 10, 'percent', '2024-01-01', NULL),
	('BLACKFRIDAY20', 20, 'percent', '2020-01-01', NULL), 
	('MINUS500FORLONGULTIMATE', 500, 'amount', '2025-06-15', NULL), 
	('MINUS200FORLONGMEDIUM', 200, 'amount', '2025-06-15', NULL);

WITH cte_dates AS(
	SELECT generate_series(
		DATE '2025-01-01',
		DATE '2025-12-31',
		INTERVAL '1 day'
	) full_date
)
INSERT INTO dim_dates(
	full_date,
	date_year,
	date_quarter,
	date_month,
	date_month_name,
	week_number,
	date_day,
	day_of_week,
	is_weekend,
	is_holiday
)
SELECT
	full_date,
	EXTRACT(YEAR FROM full_date) AS date_year,
	EXTRACT(QUARTER FROM full_date) AS date_quarter,
	EXTRACT(MONTH FROM full_date) AS date_month,
	TO_CHAR(full_date, 'FMMonth') AS date_month_name,
	EXTRACT(WEEK FROM full_date) AS week_number,
	EXTRACT(DAY FROM full_date) AS date_day,
	EXTRACT(ISODOW FROM full_date) AS day_of_week,
	CASE 
		WHEN full_date IN ('2025-01-01', '2025-02-23',
						'2025-03-08', '2025-05-01', 
						'2025-05-09', '2025-06-12', 
						'2025-11-04') THEN TRUE
		WHEN EXTRACT(ISODOW FROM full_date) IN (6, 7) THEN TRUE
		ELSE FALSE
	END AS is_weekend,
	CASE 
		WHEN full_date IN ('2025-01-01', '2025-02-23',
						'2025-03-08', '2025-05-01', 
						'2025-05-09', '2025-06-12', 
						'2025-11-04') THEN TRUE
		ELSE FALSE
	END AS is_holiday
FROM cte_dates;

WITH cte_pre_v1 AS(
  SELECT
    u.user_number 				AS user_number,
    t.tariff_number 			AS tariff_number,
    p.promocode_number 			AS promocode_number
  FROM generate_series(1, 1000) AS gs(n)
  JOIN LATERAL (
    SELECT
      user_number
    FROM dim_users
    ORDER BY random() + n * 0
    LIMIT 1
  ) u
  ON TRUE
  JOIN LATERAL (
    SELECT
      tariff_number
    FROM dim_tariffs
    ORDER BY random() + n * 0
    LIMIT 1
  ) t
  ON TRUE
  LEFT JOIN LATERAL (
    SELECT
      promocode_number
    FROM dim_promocodes
    WHERE random() < 0.3
    ORDER BY random() + n * 0
    LIMIT 1
  ) p
  ON TRUE
),
cte_pre_v2 AS(
	SELECT
		cte_1.user_number 			AS user_number,
		cte_1.tariff_number 		AS tariff_number,
		CASE 
			WHEN tar.tariff_valid_to < pro.promocode_valid_from 
			OR tar.tariff_valid_from > pro.promocode_valid_to
				THEN NULL
			ELSE cte_1.promocode_number 		
		END 						AS promocode_number,
		tar.tariff_price 			AS tariff_price,
		CASE 
			WHEN tar.tariff_valid_to < pro.promocode_valid_from 
			OR tar.tariff_valid_from > pro.promocode_valid_to
				THEN NULL
			ELSE pro.promocode_type 			
		END 						AS promocode_type,
		CASE 
			WHEN tar.tariff_valid_to < pro.promocode_valid_from 
			OR tar.tariff_valid_from > pro.promocode_valid_to
				THEN NULL
			ELSE pro.promocode_sale 			
		END							AS promocode_sale,
		CASE 
			WHEN tar.tariff_valid_to < pro.promocode_valid_from 
			OR tar.tariff_valid_from > pro.promocode_valid_to
				THEN tar.tariff_valid_from
			ELSE
				GREATEST(tar.tariff_valid_from, 
						COALESCE(pro.promocode_valid_from, '0001-01-01')) 		
		END 						AS lower_bound,
		CASE
			WHEN tar.tariff_valid_to < pro.promocode_valid_from 
			OR tar.tariff_valid_from > pro.promocode_valid_to
				THEN tar.tariff_valid_to
			ELSE
				LEAST(COALESCE(tar.tariff_valid_to, '9999-12-31'), 
						COALESCE(pro.promocode_valid_to, '9999-12-31')) 		
		END 						AS upper_bounde
	FROM cte_pre_v1 cte_1
	JOIN dim_tariffs tar
	ON cte_1.tariff_number = tar.tariff_number
	LEFT JOIN dim_promocodes pro
	ON cte_1.promocode_number = pro.promocode_number
),
cte_pre_v3 AS(
	SELECT
		cte_2.user_number 		AS user_number,
		cte_2.tariff_number 		AS tariff_number,
		cte_2.promocode_number	AS promocode_number,
		(SELECT
			date_number
		FROM dim_dates
		WHERE full_date BETWEEN cte_2.lower_bound AND cte_2.upper_bounde
		ORDER BY random()
		LIMIT 1
		) 						AS date_number,
		cte_2.tariff_price 		AS tariff_price,
		cte_2.promocode_type 		AS promocode_type,
		cte_2.promocode_sale 		AS promocode_sale
	FROM cte_pre_v2 cte_2
		
)

INSERT INTO fact_transactions(
    user_number,
    tariff_number,
    promocode_number,
    date_number,
    net_price,
  	full_price,
  	discount_amount
)

SELECT
    user_number,
    tariff_number,
    promocode_number,
    date_number,
    CASE 
      WHEN promocode_type = 'percent' 
          THEN tariff_price * (1 - promocode_sale / 100)
      WHEN promocode_type = 'amount' AND tariff_price - promocode_sale > 0 
          THEN tariff_price - promocode_sale
      WHEN promocode_type = 'amount' AND tariff_price - promocode_sale <= 0 
          THEN 1
      ELSE tariff_price
    END 				AS net_price,
  tariff_price,
  CASE
    WHEN promocode_type = 'percent' 
          THEN tariff_price * (promocode_sale / 100)
      WHEN promocode_type = 'amount' AND tariff_price - promocode_sale > 0 
          THEN promocode_sale
      WHEN promocode_type = 'amount' AND tariff_price - promocode_sale <= 0 
          THEN tariff_price - 1
      ELSE 0
  END 					AS discount_amount
FROM cte_pre_v3;


