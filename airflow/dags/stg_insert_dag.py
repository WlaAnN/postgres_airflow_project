from airflow.sdk import dag, task
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from pendulum import datetime
import pendulum
from airflow.timetables.trigger import CronTriggerTimetable
from airflow.providers.common.sql.sensors.sql import SqlSensor


ufa_tz = pendulum.tz.timezone.FixedTimezone(5 * 3600)

@dag(
    dag_id="extract_data",
    schedule=CronTriggerTimetable("30 16 * * *", timezone=ufa_tz),
    start_date=datetime(year=2026, month=6, day=14, tz=ufa_tz)
)
def extract_data():

    is_postgres_up = SqlSensor(
        task_id="is_postgres_up",
        conn_id="my_postgres_conn", 
        sql='SELECT 1;',
        timeout=180,
        poke_interval=5
    )
    
    extract_data_task = SQLExecuteQueryOperator(
        task_id="extract_data_task",
        conn_id="my_postgres_conn", 
        sql="./sql_scripts/insert_staging.sql"
    )

    @task.python
    def check():
        print("Data extracted!")

    first = is_postgres_up
    second = extract_data_task
    third = check()

    first >> second >> third

extract_data()