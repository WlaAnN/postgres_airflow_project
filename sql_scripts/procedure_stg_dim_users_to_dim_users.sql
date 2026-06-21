CREATE OR REPLACE PROCEDURE load_dim_users()
LANGUAGE plpgsql 
AS $$
	DECLARE 
		rows_amount INT;
		date_from DATE;
		date_to DATE;
	BEGIN
	
		-- Удаляем дубликаты из staging, оставляя последнюю запись по ctid
		DELETE FROM stg_dim_users 
		WHERE ctid NOT IN (
			SELECT MAX(ctid)
			FROM stg_dim_users 
			GROUP BY source_user_id
		);

		SELECT
			COUNT(*),
			MIN(create_date),
			MAX(create_date)
		INTO
			rows_amount,
			date_from,
			date_to
		FROM stg_dim_users; 
		
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
					WHEN gender IN ('M', 'Male') THEN 'M'
					WHEN gender IN ('F', 'Female') THEN 'F'
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
							WHEN EXCLUDED.gender IN ('M', 'Male') THEN 'M'
							WHEN EXCLUDED.gender IN ('F', 'Female') THEN 'F'
						ELSE 'n/a'
						END,
				is_active = TRUE
			RETURNING user_number
		)
			
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

		DELETE FROM stg_dim_users;

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