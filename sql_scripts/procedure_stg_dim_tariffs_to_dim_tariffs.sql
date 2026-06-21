CREATE OR REPLACE PROCEDURE public.load_dim_tariffs(
	)
LANGUAGE 'plpgsql'
AS $$
	DECLARE 
		rows_amount INT;
		updated_amount INT;
		inserted_amount INT;
		data_from DATE;
		data_to DATE;
		start_time TIMESTAMP;
		end_time TIMESTAMP;
	BEGIN
		--Засекаем время
		SELECT
			NOW()
		INTO
			start_time;

		--Данные о промежутке сбора данных
		RAISE NOTICE '==========================';
		RAISE NOTICE 'Loading tariffs started...';
		RAISE NOTICE '==========================';
		SELECT
			(SELECT
				COALESCE(MAX(elt.data_to), '1970-01-01')
			FROM elt_log AS elt
			WHERE table_name = 'dim_tariffs'),
			NOW()::DATE
		INTO 
			data_from,
			data_to;

		RAISE NOTICE '------------------------------------';
		RAISE NOTICE 'Cleaning stg_dim_tariffs of bad data';
		RAISE NOTICE '------------------------------------';
		--Очистка sct_dim_tariffs от ошибочных записей
		DELETE FROM stg_dim_tariffs
		WHERE ctid NOT IN
			(
			SELECT
				MAX(ctid)
			FROM stg_dim_tariffs stg
			WHERE 
			(
					tariff_valid_from > 
						(
							SELECT
								MAX(tariff_valid_to)
							FROM dim_tariffs dim
							WHERE LOWER(TRIM(dim.tariff_name)) = LOWER(TRIM(stg.tariff_name))
						) 
				AND
					(
					NOT EXISTS
						(
							SELECT	
								1
							FROM dim_tariffs dim
							WHERE LOWER(TRIM(stg.tariff_name)) = LOWER(TRIM(dim.tariff_name)) AND
									dim.tariff_valid_to IS NULL
						)
					)
				)
			OR
				EXISTS
				(
					SELECT
						1
					FROM dim_tariffs dim
					WHERE LOWER(TRIM(dim.tariff_name)) = LOWER(TRIM(stg.tariff_name)) AND
						dim.tariff_valid_to IS NULL AND
						(dim.tariff_price != stg.tariff_price OR
						dim.tariff_duration_in_days != stg.tariff_duration_in_days) AND
						stg.tariff_valid_from >= dim.tariff_valid_from
				)
			
			OR LOWER(TRIM(stg.tariff_name)) NOT IN (SELECT DISTINCT LOWER(TRIM(tariff_name)) FROM dim_tariffs)
			GROUP BY tariff_name
			);
		
		--Метаданные о stg_dim_tarrifs
		SELECT
			COUNT(*)
		INTO 
			rows_amount
		FROM stg_dim_tariffs;

		IF rows_amount = 0 THEN
			INSERT INTO elt_log(
				table_name,
				rows_amount,
				status
			)
			VALUES ('dim_tariffs', 0, 'Nothing to load');
			RAISE NOTICE '-----------------------------------------';
			RAISE NOTICE 'stg_dim_tariffs is empty. Nothing to load';
			RAISE NOTICE '-----------------------------------------';
			RETURN;
		END IF;

		RAISE NOTICE '------------------------------------';
		RAISE NOTICE 'Updating tariffs...';
		RAISE NOTICE '------------------------------------';
		--Обновление данных о тарифах
		WITH cte_update_1 AS(
		SELECT
			dim.tariff_name AS dim_tariff_name,
			stg.tariff_name AS stg_tariff_name,
			stg.tariff_valid_from AS stg_valid_from
		FROM dim_tariffs dim
		LEFT JOIN stg_dim_tariffs stg
		ON LOWER(TRIM(dim.tariff_name)) = LOWER(TRIM(stg.tariff_name))
		WHERE stg.tariff_name IS NOT NULL
		),
		cte_update_2 AS 
		(
		UPDATE dim_tariffs AS dim
		SET tariff_valid_to = cte.stg_valid_from - INTERVAL '1 day'
		FROM cte_update_1 cte
		WHERE TRIM(LOWER(dim.tariff_name)) = TRIM(LOWER(cte.dim_tariff_name)) 
			AND dim.tariff_valid_to IS NULL
		RETURNING tariff_number
		)
		SELECT
			COUNT(tariff_number)
		INTO 
			updated_amount
		FROM cte_update_2;

		RAISE NOTICE '------------------------------------';
		RAISE NOTICE 'Inserting new tariffs...';
		RAISE NOTICE '------------------------------------';
		--Вставка записей о тарифах
		WITH cte_insert AS
		(
		INSERT INTO dim_tariffs(
			tariff_name,
			tariff_price,
			tariff_duration_in_days,
			tariff_valid_from,
			tariff_valid_to
		)
		SELECT
			INITCAP(TRIM(tariff_name)),
			tariff_price,
			tariff_duration_in_days,
			tariff_valid_from,
			NULL
		FROM stg_dim_tariffs
		
		RETURNING tariff_number
		)
		SELECT
			COUNT(tariff_number)
		INTO 
			inserted_amount
		FROM cte_insert;

		RAISE NOTICE '------------------------------------';
		RAISE NOTICE 'Cleaning stg_dim_tariffs...';
		RAISE NOTICE '------------------------------------';
		--Очистка stg_dim_tariffs
		TRUNCATE stg_dim_tariffs;

		RAISE NOTICE '------------------------------------';
		RAISE NOTICE 'Logging...';
		RAISE NOTICE '------------------------------------';
		--Логирование
		INSERT INTO elt_log(
			table_name,
			rows_amount,
			data_from,
			data_to
		)
		VALUES(
			'dim_tariffs',
			inserted_amount + updated_amount,
			data_from,
			data_to);

		SELECT
			NOW()
		INTO  
			end_time;
		RAISE NOTICE '====================================';
		RAISE NOTICE 'Loading ended in %', EXTRACT(MILLISECONDS FROM end_time - start_time);
		RAISE NOTICE '====================================';
		--Обарботка ошибки вставки и обновления
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
				VALUES(
					'dim_tariffs',
					rows_amount,
					data_from,
					data_to,
					'FAILED',
					SQLERRM);
			RAISE EXCEPTION 'ОШИБКА ЗАГРУЗКИ: %', SQLERRM;
			
	END;
$$;

