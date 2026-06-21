from airflow.sdk import dag, task
from pendulum import datetime
from datetime import timedelta, timezone

ufa_tz = timezone(timedelta(hours=5))

@dag(
    dag_id="schedule_preset_dag",
    start_date = datetime(year=2026, month=5, day=2, tz=ufa_tz),
    schedule = "@daily",
    is_paused_upon_creation = False,
    catchup = True
)
def schedule_preset_dag():

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

schedule_preset_dag()