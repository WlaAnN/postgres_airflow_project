WITH cte_pre_v1 AS(
  SELECT
    u.user_number 				AS user_number,
    t.tariff_number 			AS tariff_number,
    p.promocode_number 			AS promocode_number
  FROM generate_series(1, 1000) AS gs(n)
  JOIN LATERAL (
    SELECT
      user_number
    FROM dim_users
    ORDER BY random() + n * 0
    LIMIT 1
  ) u
  ON TRUE
  JOIN LATERAL (
    SELECT
      tariff_number
    FROM dim_tariffs
    ORDER BY random() + n * 0
    LIMIT 1
  ) t
  ON TRUE
  LEFT JOIN LATERAL (
    SELECT
      promocode_number
    FROM dim_promocodes
    WHERE random() < 0.3
    ORDER BY random() + n * 0
    LIMIT 1
  ) p
  ON TRUE
),
cte_pre_v2 AS(
	SELECT
		cte_1.user_number 			AS user_number,
		cte_1.tariff_number 		AS tariff_number,
		CASE 
			WHEN tar.tariff_valid_to < pro.promocode_valid_from 
			OR tar.tariff_valid_from > pro.promocode_valid_to
				THEN NULL
			ELSE cte_1.promocode_number 		
		END 						AS promocode_number,
		tar.tariff_price 			AS tariff_price,
		CASE 
			WHEN tar.tariff_valid_to < pro.promocode_valid_from 
			OR tar.tariff_valid_from > pro.promocode_valid_to
				THEN NULL
			ELSE pro.promocode_type 			
		END 						AS promocode_type,
		CASE 
			WHEN tar.tariff_valid_to < pro.promocode_valid_from 
			OR tar.tariff_valid_from > pro.promocode_valid_to
				THEN NULL
			ELSE pro.promocode_sale 			
		END							AS promocode_sale,
		CASE 
			WHEN tar.tariff_valid_to < pro.promocode_valid_from 
			OR tar.tariff_valid_from > pro.promocode_valid_to
				THEN tar.tariff_valid_from
			ELSE
				GREATEST(tar.tariff_valid_from, 
						COALESCE(pro.promocode_valid_from, '0001-01-01')) 		
		END 						AS lower_bound,
		CASE
			WHEN tar.tariff_valid_to < pro.promocode_valid_from 
			OR tar.tariff_valid_from > pro.promocode_valid_to
				THEN tar.tariff_valid_to
			ELSE
				LEAST(COALESCE(tar.tariff_valid_to, '9999-12-31'), 
						COALESCE(pro.promocode_valid_to, '9999-12-31')) 		
		END 						AS upper_bounde
	FROM cte_pre_v1 cte_1
	JOIN dim_tariffs tar
	ON cte_1.tariff_number = tar.tariff_number
	LEFT JOIN dim_promocodes pro
	ON cte_1.promocode_number = pro.promocode_number
),
cte_pre_v3 AS(
	SELECT
		cte_2.user_number 		AS user_number,
		cte_2.tariff_number 		AS tariff_number,
		cte_2.promocode_number	AS promocode_number,
		(SELECT
			date_number
		FROM dim_dates
		WHERE full_date BETWEEN cte_2.lower_bound AND cte_2.upper_bounde
		ORDER BY random()
		LIMIT 1
		) 						AS date_number,
		cte_2.tariff_price 		AS tariff_price,
		cte_2.promocode_type 		AS promocode_type,
		cte_2.promocode_sale 		AS promocode_sale
	FROM cte_pre_v2 cte_2
		
)

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
    user_number,
    tariff_number,
    promocode_number,
    date_number,
    CASE 
      WHEN promocode_type = 'percent' 
          THEN tariff_price * (1 - promocode_sale / 100)
      WHEN promocode_type = 'amount' AND tariff_price - promocode_sale > 0 
          THEN tariff_price - promocode_sale
      WHEN promocode_type = 'amount' AND tariff_price - promocode_sale <= 0 
          THEN 1
      ELSE tariff_price
    END 				AS net_price,
  tariff_price,
  CASE
    WHEN promocode_type = 'percent' 
          THEN tariff_price * (promocode_sale / 100)
      WHEN promocode_type = 'amount' AND tariff_price - promocode_sale > 0 
          THEN promocode_sale
      WHEN promocode_type = 'amount' AND tariff_price - promocode_sale <= 0 
          THEN tariff_price - 1
      ELSE 0
  END 					AS discount_amount
FROM cte_pre_v3

