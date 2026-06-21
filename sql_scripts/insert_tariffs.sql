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
	('Long Ultimate', 5399, 365, '2025-06-01', NULL)