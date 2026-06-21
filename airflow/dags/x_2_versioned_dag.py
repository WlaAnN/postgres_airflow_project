from airflow.sdk import dag, task

@dag
def versioned_dag(
    tag: str = "versioned_dag",
):

    @task.python
    def first_task():
        print("This is my first dag")
    
    @task.python
    def second_task():
        print("This is my second task")
    
    @task.python
    def versioned_task():
        print("My versioned task lol")

    @task.python
    def new_version_task():
        print("This is the new version of the task")

    @task.python
    def old_version_task():
        for i in range(5):
            print(f"Old version of the task, iteration {i}")
    
    @task.python
    def another_old_version_task():
        for i in range(5):
            print(f"Another old version of the task, iteration {i}")

    first = first_task()
    second = second_task()
    third = versioned_task()
    fourth = new_version_task()
    fifth = old_version_task()
    sixth = another_old_version_task()

    first >> second >> third >> fourth >> fifth >> sixth

versioned_dag()