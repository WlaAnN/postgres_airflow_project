from airflow.sdk import dag, task
from pendulum import datetime
import pendulum
from airflow.timetables.trigger import CronTriggerTimetable

ufa_tz = pendulum.tz.timezone.FixedTimezone(5 * 3600)

@dag(
    dag_id="schedule_cron_dag",
    start_date = datetime(year=2026, month=6, day=3, tz=ufa_tz),
    schedule = CronTriggerTimetable("0 16 * * MON-FRI", timezone=ufa_tz), 
    is_paused_upon_creation = False,
    catchup = True
)
def schedule_cron_dag():

    @task.python
    def first_task():
        print("This is my first dag")
    
    @task.python
    def second_task():
        print("This is my second task")
    
    @task.python
    def third_task():
        print("My third task lol")


    first = first_task()
    second = second_task()
    third = third_task()

    first >> second >> third 

schedule_cron_dag()