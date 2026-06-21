CREATE OR REPLACE PROCEDURE load_dim_promocodes() 
LANGUAGE plpgsql
AS $$
	DECLARE 
		rows_amount INT;
		updated_amount INT;
		inserted_amount INT;
		data_from DATE;
		data_to DATE;
	BEGIN
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
					WHERE dim.promocode_code = stg.promocode_code
							AND dim.promocode_valid_to IS NULL
				) 
			OR 
				(
					NOT EXISTS
					(
						SELECT
							1
						FROM dim_promocodes dim
						WHERE dim.promocode_valid_to IS NULL AND dim.promocode_code = stg.promocode_code
					)
			
				AND
			
					promocode_valid_from > 
					(
						SELECT
							MAX(promocode_valid_to)
						FROM dim_promocodes dim
						WHERE dim.promocode_code = stg.promocode_code 
					)
				)
			OR 
				EXISTS
				(
					SELECT
						1
					FROM dim_promocodes dim
					WHERE dim.promocode_code = stg.promocode_code AND
						dim.promocode_valid_to IS NULL AND
						(dim.promocode_type != stg.promocode_type OR
						dim.promocode_sale != stg.promocode_sale)
				)
			
			OR stg.promocode_code NOT IN (SELECT DISTINCT promocode_code FROM dim_promocodes)
			GROUP BY promocode_code
			);
			
		--Метаданные о stg_dim_promocodes
		SELECT
			COUNT(*)
		INTO 
			rows_amount
		FROM stg_dim_promocodes;

		--Обновление данных о промокодах
		WITH cte_update_1 AS(
		SELECT
			dim.promocode_code AS dim_promocode_code,
			stg.promocode_code AS stg_promocode_code,
			stg.promocode_valid_from AS stg_valid_from
		FROM dim_promocodes dim
		LEFT JOIN stg_dim_promocodes stg
		ON dim.promocode_code = stg.promocode_code
		WHERE stg.promocode_code IS NOT NULL
		),
		cte_update_2 AS 
		(
		UPDATE dim_promocodes AS dim
		SET promocode_valid_to = cte.stg_valid_from - INTERVAL '1 day'
		FROM cte_update_1 cte
		WHERE dim.promocode_code = cte.dim_promocode_code AND dim.promocode_valid_to IS NULL
		RETURNING promocode_number
		)
		SELECT
			COUNT(promocode_number)
		INTO 
			updated_amount
		FROM cte_update_2;

		--Вставка записей о тарифах
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
			promocode_code,
			promocode_sale,
			promocode_type,
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
		DELETE FROM stg_dim_promocodes;

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