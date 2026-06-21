from airflow.sdk import dag, task

@dag
def first_orchestrate_dag(
    tag: str = "first_orchestrate_dag",
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

    @task.python
    def write_to_file():
        with open("/opt/airflow/logs/data/data_parent_check.txt", 'w') as file:
            file.write("This means that the first dag was triggered")

    first = first_task()
    second = second_task()
    third = third_task()
    fourth = write_to_file()
    
    first >> second >> third >> fourth

first_orchestrate_dag()