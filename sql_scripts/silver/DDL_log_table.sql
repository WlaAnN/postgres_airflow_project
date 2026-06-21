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