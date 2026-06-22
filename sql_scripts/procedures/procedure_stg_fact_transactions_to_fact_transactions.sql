CREATE OR REPLACE PROCEDURE load_fact_transactions()
LANGUAGE plpgsql
AS $$
	DECLARE 
		rows_amount INT;
		data_from DATE;
		data_to DATE;
		start_time TIMESTAMP;
		end_time TIMESTAMP;
	BEGIN

		EXECUTE 'SET LOCAL max_parallel_workers_per_gather = 0';
    	EXECUTE 'SET LOCAL max_parallel_workers = 0';

		SELECT
			NOW()
		INTO 
			start_time;
		RAISE NOTICE '=====================================';
		RAISE NOTICE 'Loading fact_transactions started....';
		RAISE NOTICE '=====================================';
		SELECT
			COUNT(*),
			MIN(transaction_date),
			MAX(transaction_date)
		INTO 
			rows_amount,
			data_from,
			data_to
		FROM stg_fact_transactions;

		--Обработка ситуации пустой stg таблицы
		IF rows_amount = 0 THEN 
			INSERT INTO elt_log(
				table_name,
				rows_amount,
				status
			)
			VALUES ('fact_transactions', 0, 'Nothing to load');
			RAISE NOTICE '------------------------------------------------';
			RAISE NOTICE 'stg_fact_transactions is empty, nothing to load.';
			RAISE NOTICE '------------------------------------------------';
			RETURN;
		END IF;

		--Добавление дат, если они закончились в таблице dim_dates
		IF EXISTS(
			SELECT
				1
			FROM stg_fact_transactions tra
			LEFT JOIN dim_dates dat
			ON tra.transaction_date = dat.full_date
			WHERE dat.full_date IS NULL AND tra.transaction_date <= NOW()::DATE
			)
		THEN 
			RAISE NOTICE '--------------------------------------';
			RAISE NOTICE 'Dates update needed: staring update...';
			CALL load_dim_dates();
			RAISE NOTICE 'Dates updated.';
			RAISE NOTICE '--------------------------------------';
		END IF;

		--Вставка новых строк
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
		WHERE tra.transaction_date <= NOW()::DATE 
			AND tra.full_price = tra.net_price + tra.discount_amount
			AND (tra.transaction_date >= tar.tariff_valid_from 
				AND (tra.transaction_date <= tar.tariff_valid_to OR tar.tariff_valid_to IS NULL))
			AND 
			(
			tra.promocode_code IS NULL
			OR
			(tra.transaction_date >= pro.promocode_valid_from 
				AND (tra.transaction_date <= pro.promocode_valid_to OR pro.promocode_valid_to IS NULL))
			)
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
		RAISE NOTICE '-------------------------------------------------';
		RAISE NOTICE 'Loading fact_transactions comleted. Logs updated.';
		RAISE NOTICE '-------------------------------------------------';
		RAISE NOTICE 'Cleaning stg_fact_transactions';
		RAISE NOTICE '-------------------------------------------------';
		TRUNCATE stg_fact_transactions;
		SELECT
			NOW()
		INTO 
			end_time;
		RAISE NOTICE '======================';
		RAISE NOTICE 'Loading ended in %', EXTRACT(MILLISECONDS FROM end_time - start_time);
		RAISE NOTICE '======================';
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