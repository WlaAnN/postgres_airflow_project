from airflow.sdk import EventsTimetable, dag, task
from pendulum import datetime
import pendulum
from airflow.timetables.events import EventsTimetable

ufa_tz = pendulum.tz.timezone.FixedTimezone(5 * 3600)

special_datas = EventsTimetable(event_dates=[
    datetime(year=2026, month=1, day=1, tz=ufa_tz),
    datetime(year=2026, month=2, day=14, tz=ufa_tz),
    datetime(year=2026, month=3, day=8, tz=ufa_tz),
    datetime(year=2026, month=4, day=5, tz=ufa_tz),
    datetime(year=2026, month=5, day=1, tz=ufa_tz)
])

@dag(
    schedule=special_datas,
    start_date=datetime(year=2026, month=1, day=1, tz=ufa_tz),
    dag_id = "events_dag",
    end_date = datetime(year=2026, month=6, day=6, tz=ufa_tz),
    is_paused_upon_creation = False,
    catchup = True
)
def events_dag():
    
    @task.python
    def print_event_date(**kwargs):
        event_date = kwargs['logical_date']
        print (f"Today is a special day: {event_date}")

    @task.bash
    def bash_print_event_date():
        return "echo 'Today is a special day: {{ logical_date }}'"
    
    python_task = print_event_date()        
    bash_task = bash_print_event_date()

    python_task >> bash_task

events_dag()