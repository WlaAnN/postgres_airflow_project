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
	('MINUS200FORLONGMEDIUM', 200, 'amount', '2025-06-15', NULL)
