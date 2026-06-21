from airflow.sdk import dag
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
import pendulum
from airflow.providers.common.sql.sensors.sql import SqlSensor

ufa_tz = pendulum.tz.timezone.FixedTimezone(3600 * 5)

@dag(
    dag_id="db_init_dag", 
    schedule="@once",
    start_date=pendulum.datetime(year=2026, month=1, day=1, tz=ufa_tz),
    catchup=False,
    is_paused_upon_creation=False,
)
def db_init_dag():

    is_postgres_up = SqlSensor(
        task_id="is_postgres_up",
        conn_id="my_postgres_conn", 
        sql='SELECT 1;',
        timeout=180,
        poke_interval=5
    )

    create_bronze = SQLExecuteQueryOperator(
        task_id="create_bronze", 
        conn_id="my_postgres_conn", 
        sql='./sql_scripts/bronze/DDL_bronze.sql'
    )

    create_silver = SQLExecuteQueryOperator(
        task_id="create_silver", 
        conn_id="my_postgres_conn", 
        sql='./sql_scripts/silver/DDL_silver.sql'
    )

    create_log = SQLExecuteQueryOperator(
        task_id="create_log", 
        conn_id="my_postgres_conn", 
        sql="./sql_scripts/silver/DDL_log_table.sql"
    )

    create_gold  = SQLExecuteQueryOperator(
        task_id="create_gold", 
        conn_id="my_postgres_conn", 
        sql="./sql_scripts/gold/DDL_gold.sql"
    )

    dates_procedure = SQLExecuteQueryOperator(
        task_id="dates_procedure",
        conn_id="my_postgres_conn", 
        sql="./sql_scripts/procedures/" \
        "procedure_load_dates.sql"
    )

    users_procedure = SQLExecuteQueryOperator(
        task_id="users_procedure",
        conn_id="my_postgres_conn", 
        sql="./sql_scripts/procedures/" \
        "procedure_stg_dim_users_to_dim_users.sql"
    )

    tariffs_procedure = SQLExecuteQueryOperator(
        task_id="tariffs_procedure",
        conn_id="my_postgres_conn", 
        sql="./sql_scripts/procedures/" \
        "procedure_stg_dim_tariffs_to_dim_tariffs.sql"
    )

    promocodes_procedure = SQLExecuteQueryOperator(
        task_id="promocodes_procedure",
        conn_id="my_postgres_conn", 
        sql="./sql_scripts/procedures/" \
        "procedure_stg_dim_promocodes_to_dim_promocodes.sql"
    )

    transactions_procedure = SQLExecuteQueryOperator(
        task_id="transactions_procedure",
        conn_id="my_postgres_conn", 
        sql="./sql_scripts/procedures/" \
        "procedure_stg_fact_transactions_to_fact_transactions.sql"
    )

    is_postgres_up >> create_bronze >> [create_silver, create_log] >> \
    create_gold >> [dates_procedure, users_procedure, \
    tariffs_procedure, promocodes_procedure, transactions_procedure]
    

db_init_dag()   