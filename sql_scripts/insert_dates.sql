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
		WHEN EXTRACT(DOW FROM full_date) IN (6, 7) THEN TRUE
		ELSE FALSE
	END AS is_weekend,
	CASE 
		WHEN full_date IN ('2025-01-01', '2025-02-23',
						'2025-03-08', '2025-05-01', 
						'2025-05-09', '2025-06-12', 
						'2025-11-04') THEN TRUE
		ELSE FALSE
	END AS is_holiday
FROM cte_dates