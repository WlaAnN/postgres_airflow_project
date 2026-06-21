CREATE OR REPLACE PROCEDURE load_fact_transactions()
LANGUAGE plpgsql
AS $$
	DECLARE 
		rows_amount INT;
		data_from DATE;
		data_to DATE;
	BEGIN
		SELECT
			COUNT(*),
			MIN(transaction_date),
			MAX(transaction_date)
		INTO 
			rows_amount,
			data_from,
			data_to
		FROM stg_fact_transactions;
		
		IF EXISTS(
			SELECT
				1
			FROM stg_fact_transactions tra
			LEFT JOIN dim_dates dat
			ON tra.transaction_date = dat.full_date
			WHERE dat.full_date IS NULL
			)
		THEN CALL load_dim_dates();
		END IF;

		WITH cte_insert AS
		(
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
			use.user_number,
			tar.tariff_number,
			pro.promocode_number,
			dat.date_number,
			tra.net_price,
			tra.full_price,
			tra.discount_amount
		FROM stg_fact_transactions tra
		JOIN dim_users use
		ON use.source_user_id = tra.source_user_id
		JOIN dim_tariffs tar
		ON tar.tariff_name = tra.tariff_name
		LEFT JOIN dim_promocodes pro
		ON pro.promocode_code = tra.promocode_code
		JOIN dim_dates dat
		ON dat.full_date = tra.transaction_date
		RETURNING user_number
		)
		INSERT INTO elt_log(
			table_name,
			rows_amount,
			data_from,
			data_to
		)
		SELECT
			'fact_transactions',
			COUNT(user_number),
			data_from,
			data_to
		FROM cte_insert;

		DELETE FROM stg_fact_transactions;
		
	EXCEPTION 
		WHEN OTHERS THEN	
			INSERT INTO elt_log(
				table_name,
				rows_amount,
				data_from,
				data_to,
				status,
				error_message
			)
			VALUES('fact_transactions', rows_amount, data_from, data_to, 'FAILED', SQLERRM);
		RAISE EXCEPTION 'ОШИБКА ЗАГРУЗКИ: %', SQLERRM;
	END;
$$;




