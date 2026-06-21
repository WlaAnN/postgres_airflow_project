from airflow.sdk import dag, task
from pendulum import datetime
import pendulum
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.timetables.trigger import CronTriggerTimetable

ufa_tz = pendulum.tz.timezone.FixedTimezone(5 * 3600)

@dag(
    dag_id="clean_and_load_data",
    schedule=CronTriggerTimetable("0 17 * * *", timezone=ufa_tz),
    start_date=datetime(year=2026, month=6, day=15, tz=ufa_tz)
)
def clean_load_data():

    load_users = SQLExecuteQueryOperator(
        task_id="load_users",
        conn_id="my_postgres_conn",
        sql="CALL load_dim_users();"
    )

    load_tariffs = SQLExecuteQueryOperator(
        task_id="load_tariffs",
        conn_id="my_postgres_conn",
        sql="CALL load_dim_tariffs();"
    )

    load_promocodes = SQLExecuteQueryOperator(
        task_id="load_promocodes",
        conn_id="my_postgres_conn",
        sql="CALL load_dim_promocodes();"
    )

    load_transactions = SQLExecuteQueryOperator(
        task_id="load_transactions",
        conn_id="my_postgres_conn",
        sql="CALL load_fact_transactions();"
    )

    [load_users, load_tariffs, load_promocodes] >> load_transactions

clean_load_data() 