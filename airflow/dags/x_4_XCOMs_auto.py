from airflow.sdk import dag, task

@dag
def xcoms_auto_dag(
        tag="xcoms_auto_dag"
):
    @task.python
    def first_task():
        print("This is my first task")
        fetched_data = {"data":[1,2,3,4,5]}
        return fetched_data
    
    @task.python
    def second_task(data: dict):
        
        feched_data = data["data"]
        print("Transforming data...")
        transformed_data = feched_data * 2
        transformed_data_dict = {"transformed_data":transformed_data}
        return transformed_data_dict
    
    @task.python
    def third_task(data: dict):
        print("Loading data")
        load_data = data["transformed_data"]
        return load_data
    
    first = first_task()
    second = second_task(first)
    third = third_task(second)

xcoms_auto_dag()