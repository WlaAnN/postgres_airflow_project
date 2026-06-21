from airflow.sdk import dag, task

@dag
def second_orchestrate_dag(
    tag: str = "second_orchestrate_dag",
):

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

second_orchestrate_dag()