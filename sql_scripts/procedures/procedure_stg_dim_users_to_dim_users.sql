CREATE OR REPLACE PROCEDURE load_dim_users()
LANGUAGE plpgsql 
AS $$
	DECLARE 
		rows_amount INT;
		date_from DATE;
		date_to DATE;
		start_time TIMESTAMP;
		end_time TIMESTAMP;
	BEGIN
		--Засекаем время
		SELECT
			NOW()
		INTO 
			start_time;
		
		RAISE NOTICE '==========================';
		RAISE NOTICE 'Loading users started';
		RAISE NOTICE '==========================';
		RAISE NOTICE '------------------------------------';
		RAISE NOTICE 'Cleaning stg_dim_users of dublicates';
		RAISE NOTICE '------------------------------------';

		-- Уаление дубликатов из stg_dim_users
		DELETE FROM stg_dim_users
		WHERE ctid NOT IN
		(
			SELECT
				MAX(ctid)
			FROM stg_dim_users
			GROUP BY source_user_id
		)
		OR create_date > NOW()::DATE;

		
		-- Метаданные о stg_dim_users
		SELECT
			COUNT(*),
			MIN(create_date),
			MAX(create_date)
		INTO
			rows_amount,
			date_from,
			date_to
		FROM stg_dim_users; 
	
		--Обработка ситуации пустой stg таблицы
		IF rows_amount = 0 THEN
			INSERT INTO elt_log(
				table_name,
				rows_amount,
				status
			)
			VALUES ('dim_users', 0, 'Nothing to load');
			RAISE NOTICE '----------------------------------------';
			RAISE NOTICE 'stg_dim_users is empty, nothing to load.';
			RAISE NOTICE '----------------------------------------';
			RETURN;
		END IF;

		RAISE NOTICE '----------------------------------------';
		RAISE NOTICE 'Inserting and updating users, logging...';
		RAISE NOTICE '----------------------------------------';
		-- Вставка и обновление данных в dim_users
		WITH cte_loaded_users AS
		(
		INSERT INTO dim_users(
			source_user_id,
			first_name,
			last_name,
			birth_date,
			gender,
			create_date,
			is_active
		)
		SELECT
			source_user_id,
			TRIM(first_name) AS first_name,
			TRIM(last_name) AS last_name,
			birth_date,
			CASE 
				WHEN LOWER(TRIM(gender)) IN ('m', 'male') THEN 'M'
				WHEN LOWER(TRIM(gender)) IN ('f', 'female') THEN 'F'
				ELSE 'n/a'
			END gender,
			create_date,
			TRUE
		FROM stg_dim_users
		ON CONFLICT(source_user_id)
		DO UPDATE SET 
			first_name = TRIM(EXCLUDED.first_name),
			last_name = TRIM(EXCLUDED.last_name),
			birth_date = EXCLUDED.birth_date,
			gender = CASE 
						WHEN LOWER(TRIM(EXCLUDED.gender)) IN ('M', 'Male') THEN 'M'
						WHEN LOWER(TRIM(EXCLUDED.gender)) IN ('F', 'Female') THEN 'F'
					ELSE 'n/a'
					END,
			is_active = True
		RETURNING user_number
		)
		
		-- Логирование вставки и оновления данных
		INSERT INTO elt_log(
			table_name,
			rows_amount,
			data_from,
			data_to
		)
		SELECT	
			'dim_users',
			COUNT(user_number),
			date_from,
			date_to
		FROM cte_loaded_users;
		RAISE NOTICE '------------------------------------';
		RAISE NOTICE 'Cleaning stg_dim_users';
		RAISE NOTICE '------------------------------------';
		--Очистка stg_dim_users
		TRUNCATE stg_dim_users;
		SELECT
			NOW()
		INTO 
			end_time;

		RAISE NOTICE '====================================';
		RAISE NOTICE 'Loading ended in %', EXTRACT(MILLISECONDS FROM end_time - start_time);
		RAISE NOTICE '====================================';
		--Обработка ошибки вставки и запись лога об ошибке
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
				VALUES
				('dim_users', rows_amount, date_from, date_to, 'FAILED', SQLERRM);
			RAISE EXCEPTION 'ОШИБКА ЗАГРУЗКИ: %', SQLERRM;
	END;
$$;