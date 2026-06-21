CREATE OR REPLACE PROCEDURE load_dim_promocodes() 
LANGUAGE plpgsql
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
		RAISE NOTICE '=============================';
		RAISE NOTICE 'Loading promocodes started...';
		RAISE NOTICE '=============================';

		--Данные о промежутке сбора данных
		SELECT
			(SELECT
				COALESCE(MAX(elt.data_to), '1970-01-01')
			FROM elt_log AS elt
			WHERE table_name = 'dim_promocodes'),
			NOW()::DATE
		INTO 
			data_from,
			data_to;

		--Очистка sct_dim_promocodes от ошибочных записей
		RAISE NOTICE '--------------------------------------------';
		RAISE NOTICE 'Cleaning stg_dim_promocodes from bad data...';
		RAISE NOTICE '--------------------------------------------';
		DELETE FROM stg_dim_promocodes
		WHERE ctid NOT IN
			(
			SELECT
				MAX(ctid)
			FROM stg_dim_promocodes stg
			WHERE 
				promocode_valid_from > 
				(
					SELECT
						promocode_valid_from
					FROM dim_promocodes dim
					WHERE TRIM(UPPER(dim.promocode_code)) = TRIM(UPPER(stg.promocode_code))
							AND dim.promocode_valid_to IS NULL
				) 
			OR 
				(
					NOT EXISTS
					(
						SELECT
							1
						FROM dim_promocodes dim
						WHERE dim.promocode_valid_to IS NULL 
							AND TRIM(UPPER(dim.promocode_code)) = TRIM(UPPER(stg.promocode_code))
					)
			
				AND
			
					promocode_valid_from > 
					(
						SELECT
							MAX(promocode_valid_to)
						FROM dim_promocodes dim
						WHERE TRIM(UPPER(dim.promocode_code)) = TRIM(UPPER(stg.promocode_code))
					)
				)
			OR 
				EXISTS
				(
					SELECT
						1
					FROM dim_promocodes dim
					WHERE TRIM(UPPER(dim.promocode_code)) = TRIM(UPPER(stg.promocode_code)) AND
						dim.promocode_valid_to IS NULL AND
						(dim.promocode_type != stg.promocode_type OR
						dim.promocode_sale != stg.promocode_sale)
				)
			
			OR TRIM(UPPER(stg.promocode_code)) 
				NOT IN (SELECT DISTINCT TRIM(UPPER(promocode_code)) FROM dim_promocodes)
			GROUP BY promocode_code
			)
		OR TRIM(LOWER(promocode_type)) NOT IN ('percent', 'amount');
			
		--Метаданные о stg_dim_promocodes
		SELECT
			COUNT(*)
		INTO 
			rows_amount
		FROM stg_dim_promocodes;

		--Обработка ситуации пустой таблицы stg_dim_promocodes
		IF rows_amount = 0 THEN
			INSERT INTO elt_log(
				table_name,
				rows_amount,
				status
			)
			VALUES ('dim_promocodes', 0, 'Nothing to load');
			RAISE NOTICE '--------------------------------------------';
			RAISE NOTICE 'stg_dim_promocodes is empty. Nothing to load';
			RAISE NOTICE '--------------------------------------------';
			RETURN;
		END IF;

		--Обновление данных о промокодах
		RAISE NOTICE '--------------------------------------------';
		RAISE NOTICE 'Updating promocodes...';
		RAISE NOTICE '--------------------------------------------';
		WITH cte_update_1 AS(
		SELECT
			dim.promocode_code AS dim_promocode_code,
			stg.promocode_code AS stg_promocode_code,
			stg.promocode_valid_from AS stg_valid_from
		FROM dim_promocodes dim
		LEFT JOIN stg_dim_promocodes stg
		ON TRIM(UPPER(dim.promocode_code)) = TRIM(UPPER(stg.promocode_code))
		WHERE stg.promocode_code IS NOT NULL
		),
		cte_update_2 AS 
		(
		UPDATE dim_promocodes AS dim
		SET promocode_valid_to = cte.stg_valid_from - INTERVAL '1 day'
		FROM cte_update_1 cte
		WHERE TRIM(UPPER(dim.promocode_code)) = TRIM(UPPER(cte.dim_promocode_code)) 
			AND dim.promocode_valid_to IS NULL
		RETURNING promocode_number
		)
		SELECT
			COUNT(promocode_number)
		INTO 
			updated_amount
		FROM cte_update_2;

		--Вставка записей о тарифах
		RAISE NOTICE '--------------------------------------------';
		RAISE NOTICE 'Inserting new promocodes...';
		RAISE NOTICE '--------------------------------------------';
		WITH cte_insert AS
		(
		INSERT INTO dim_promocodes(
			promocode_code,
			promocode_sale,
			promocode_type,
			promocode_valid_from,
			promocode_valid_to
		)
		SELECT
			UPPER(TRIM(promocode_code)),
			promocode_sale,
			TRIM(LOWER(promocode_type)),
			promocode_valid_from,
			promocode_valid_to
		FROM stg_dim_promocodes
		RETURNING promocode_number
		)
		SELECT
			COUNT(promocode_number)
		INTO 
			inserted_amount
		FROM cte_insert;
	
		--Очистка stg_dim_tariffs
		RAISE NOTICE '--------------------------------------------';
		RAISE NOTICE 'Cleaning stg_dim_promocodes...';
		RAISE NOTICE '--------------------------------------------';
		TRUNCATE stg_dim_promocodes;

		RAISE NOTICE '--------------------------------------------';
		RAISE NOTICE 'Logging...';
		RAISE NOTICE '--------------------------------------------';
		--Логирование
		INSERT INTO elt_log(
			table_name,
			rows_amount,
			data_from,
			data_to
		)
		VALUES(
			'dim_promocodes',
			inserted_amount + updated_amount,
			data_from,
			data_to);

		SELECT
			NOW()
		INTO 
			end_time;

		RAISE NOTICE '============================================';
		RAISE NOTICE 'Loading ended in %', EXTRACT(MILLISECONDS FROM end_time - start_time);
		RAISE NOTICE '============================================';
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
					'dim_promocodes',
					rows_amount,
					data_from,
					data_to,
					'FAILED',
					SQLERRM);
			RAISE EXCEPTION 'ОШИБКА ЗАГРУЗКИ: %', SQLERRM;
			
	END;
$$;