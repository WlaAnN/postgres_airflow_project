from airflow.sdk import dag, task

@dag
def xcoms_manual_dag(
        tag="xcoms_manual_dag"
):
    @task.python
    def first_task(**kwargs):

        ti = kwargs["ti"]
        print("This is my first task")
        fetched_data = {"data":[1,2,3,4,5]}
        ti.xcom_push(key="return_result", value=fetched_data)
    
    @task.python
    def second_task(**kwargs):
        
        ti = kwargs["ti"]
        fetched_data = ti.xcom_pull(task_ids="first_task", key="return_result")["data"]
        print("Transforming data...")
        transformed_data = fetched_data * 2
        transformed_data_dict = {"transformed_data":transformed_data}
        ti.xcom_push(key="second_task", value=transformed_data_dict)
    
    @task.python
    def third_task(**kwargs):
        ti = kwargs["ti"]
        print("Loading data")
        load_data = ti.xcom_pull(task_ids="second_task", key="second_task")["transformed_data"]
        return load_data
    
    first = first_task()
    second = second_task()
    third = third_task()

    first >> second >> third

xcoms_manual_dag()