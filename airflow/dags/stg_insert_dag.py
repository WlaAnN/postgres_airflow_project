from airflow.sdk import dag, task
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from pendulum import datetime
import pendulum
from airflow.timetables.trigger import CronTriggerTimetable

ufa_tz = pendulum.tz.timezone.FixedTimezone(5 * 3600)

@dag(
    dag_id="extract_data",
    schedule=CronTriggerTimetable("30 16 * * *", timezone=ufa_tz),
    start_date=datetime(year=2026, month=6, day=14, tz=ufa_tz)
)
def extract_data():
    
    extract_data_task = SQLExecuteQueryOperator(
        task_id="extract_data_task",
        conn_id="my_postgres_conn", 
        sql="./sql_scripts/insert_staging.sql"
    )

    @task.python
    def check():
        print("Data extracted!")

    first = extract_data_task
    second = check()

    first >> second

extract_data()