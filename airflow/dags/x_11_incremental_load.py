from airflow.sdk import dag, task
from pendulum import datetime
import pendulum
from airflow.timetables.interval import CronDataIntervalTimetable

ufa_tz = pendulum.tz.timezone.FixedTimezone(5 * 3600)

@dag(
    schedule=CronDataIntervalTimetable("@daily", timezone=ufa_tz),
    start_date=datetime(year=2026, month=6, day=2, tz=ufa_tz),
    dag_id = "incremental_load_dag",
    end_date = datetime(year=2026, month=6, day=6, tz=ufa_tz),
    is_paused_upon_creation = False,
    catchup = True
)
def incremental_load_dag():
    
    @task.python
    def incremental_data_fetch(**kwargs):
        data_interval_start = kwargs['data_interval_start']
        data_interval_end = kwargs['data_interval_end']
        print (f"Fetching data from {data_interval_start} to {data_interval_end}")

    @task.bash
    def incremental_date_process():
        return "echo 'Processing data from {{ data_interval_start }} to {{ data_interval_end }}'"
    

    python_task = incremental_data_fetch()
    bash_task = incremental_date_process()

    python_task >> bash_task

incremental_load_dag()