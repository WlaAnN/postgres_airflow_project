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
FROM cte_names