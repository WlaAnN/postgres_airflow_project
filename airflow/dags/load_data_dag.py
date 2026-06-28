from airflow.sdk import dag, task
from pendulum import datetime
import pendulum
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.timetables.trigger import CronTriggerTimetable
from airflow.providers.common.sql.sensors.sql import SqlSensor


ufa_tz = pendulum.tz.timezone.FixedTimezone(5 * 3600)

@dag(
    dag_id="clean_and_load_data",
    schedule=CronTriggerTimetable("0 17 * * *", timezone=ufa_tz),
    start_date=datetime(year=2026, month=6, day=15, tz=ufa_tz)
)
def clean_load_data():

    is_postgres_up = SqlSensor(
        task_id="is_postgres_up",
        conn_id="my_postgres_conn", 
        sql='SELECT 1;',
        timeout=180,
        poke_interval=5
    )

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

    @task.bash(
            cwd="/opt/airflow/dags/sql_scripts"
    )
    def test_data():
        return 'psql "postgresql://postgres:postgres@my_postgres:5432/project_db" '\
        '-f run_all_tests.sql'

    test = test_data()

    is_postgres_up >> load_users >> load_tariffs >> \
    load_promocodes >> load_transactions >> \
    test

clean_load_data() 