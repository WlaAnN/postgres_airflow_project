from airflow.sdk import dag, task

@dag
def first_dag(
    tag: str = "first_dag",
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
    def versioned_task():
        print("My versioned task lol")
    
    @task.python
    def new_version_task():
        print("This is the new version of the task")

    first = first_task()
    second = second_task()
    third = third_task()
    fourth = versioned_task()
    fifth = new_version_task()

    first >> second >> third >> fourth >> fifth

first_dag()