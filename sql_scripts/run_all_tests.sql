\echo '===Running tests'

--======================
--Первый уровень
--======================

\echo '----------------'
\echo 'First layer'
\echo '----------------'

\echo 'Check dim_dates not empty'
\i tests/level_1/test_dim_dates_not_empty.sql

\echo 'Check dim_users not empty'
\i tests/level_1/test_dim_users_not_empty.sql

\echo 'Check dim_tariffs not empty'
\i tests/level_1/test_dim_tariffs_not_empty.sql

\echo 'Check dim_promocodes not empty'
\i tests/level_1/test_dim_promocodes_not_empty.sql

\echo 'Check fact_transactions not empty'
\i tests/level_1/test_fact_transactions_not_empty.sql

\echo 'Check sales math in fact_transactions 1'
\i tests/level_1/test_discount_math_1.sql

\echo 'Check sales math in fact_transactions 2'
\i tests/level_1/test_discount_math_2.sql

\echo 'Check trasnsactions sum math'
\i tests/level_1/test_net_price_math.sql

\echo 'Check dates in fact_transactions'
\i tests/level_1/test_transactions_dates.sql

\echo 'Check foreign keys in fact_transactions'
\i tests/level_1/test_fact_transactions_fk_integrity.sql

--======================
--Второй уровень
--======================

\echo '----------------'
\echo 'Second layer'
\echo '----------------'

\echo 'Check rows amount'
\i tests/level_2/test_amount_of_rows.sql

\echo 'Check math first layer to second'
\i tests/level_2/test_math_from_level_1_to_second.sql

\echo 'Check promocode_is_used flag'
\i tests/level_2/test_promocodes.sql

--======================
--Третий уровень
--======================

\echo '----------------'
\echo 'Third layer'
\echo '----------------'

\echo 'Check amount in final full mart'
\i tests/level_3/test_amount_v_summary.sql

\echo 'Check math from second layer to third'
\i tests/level_3/test_math_from_level_2_to_third.sql

\echo 'Check math from second layer to year mart'
\i tests/level_3/test_math_from_v_data_mart_to_v_by_year_mart.sql

\echo 'Check math from second layer to quarter mart'
\i tests/level_3/test_math_from_v_data_mart_to_v_by_quarter_mart.sql

\echo 'Check math from second layer to month mart '
\i tests/level_3/test_math_from_v_data_mart_to_v_by_month_mart.sql

\echo 'Check math from second layer to week mart'
\i tests/level_3/test_math_from_v_data_mart_to_v_by_week_mart.sql

\echo 'Check math from second layer to day mart'
\i tests/level_3/test_math_from_v_data_mart_to_v_by_day_mart.sql

\echo 'Check math from second layer to tariff mart'
\i tests/level_3/test_math_from_v_data_mart_to_v_by_tariff_mart.sql

\echo 'Check math from second layer to promocode mart'
\i tests/level_3/test_math_from_v_data_mart_to_v_by_promocode_mart.sql

\echo 'All tests finished. If at least one test returned >=1? then there is a data issue'

