from airflow.sdk import dag, task

@dag(
        dag_id="branch_dag",
)
def branch_dag():

    @task.python
    def data_extraction(**kwargs):
        print("Extracting data...")
        ti = kwargs["ti"]
        extracted_data_dict = {"api_extracted_data":[1,2,3,4,5], 
                               "db_extracted_data":[6,7,8,9,10],
                               "s3_extracted_data":[11,12,13,14,15],
                               "weekend_flag": "false"}
        ti.xcom_push(key="return_extracted_data", value=extracted_data_dict)

    @task.python
    def transform_api_data(**kwargs):
        ti = kwargs["ti"]
        extracted_data = ti.xcom_pull(task_ids="data_extraction", key="return_extracted_data")["api_extracted_data"]
        print("Transforming API data...")
        transformed_api_data = [i*2 for i in extracted_data]
        transformed_api_data_dict = {"transformed_api_data":transformed_api_data}
        ti.xcom_push(key="return_transformed_api_data", value=transformed_api_data_dict)

    @task.python
    def transform_db_data(**kwargs):
        ti = kwargs["ti"]
        extracted_data = ti.xcom_pull(task_ids="data_extraction", key="return_extracted_data")["db_extracted_data"]
        print("Transforming DB data...")
        transformed_db_data = [i*3 for i in extracted_data]
        transformed_db_data_dict = {"transformed_db_data":transformed_db_data}
        ti.xcom_push(key="return_transformed_db_data", value=transformed_db_data_dict)

    @task.python
    def transform_s3_data(**kwargs):
        ti = kwargs["ti"]
        extracted_data = ti.xcom_pull(task_ids="data_extraction", key="return_extracted_data")["s3_extracted_data"]
        print("Transforming S3 data...")
        transformed_s3_data = [i*4 for i in extracted_data]
        transformed_s3_data_dict = {"transformed_s3_data":transformed_s3_data}
        ti.xcom_push(key="return_transformed_s3_data", value=transformed_s3_data_dict)

    @task.branch
    def decider(**kwargs):
        ti = kwargs["ti"]
        flag = ti.xcom_pull(task_ids="data_extraction", key="return_extracted_data")["weekend_flag"]
        if flag == "true":
            return 'no_load_task'
        else:
            return 'Load_data'

    @task.bash
    def Load_data(**kwargs):
        print("Loading data...")
        api_data = kwargs["ti"].xcom_pull(task_ids="transform_api_data", key="return_transformed_api_data")["transformed_api_data"]
        db_data = kwargs["ti"].xcom_pull(task_ids="transform_db_data", key="return_transformed_db_data")["transformed_db_data"]
        s3_data = kwargs["ti"].xcom_pull(task_ids="transform_s3_data", key="return_transformed_s3_data")["transformed_s3_data"]
        return f"echo 'Loaded data: {api_data}, {db_data}, {s3_data}'"
    
    @task.bash
    def no_load_task():
        print("No load task executed as it's a weekend.")
        return "echo 'No data loaded due to weekend.'"

    

    extraction = data_extraction()
    transform_api = transform_api_data()
    transform_db = transform_db_data()
    transform_s3 = transform_s3_data()
    load_db = Load_data()
    no_load = no_load_task()

    decide = decider()
    
    extraction >> [transform_api, transform_db, transform_s3] >> decide >> [load_db, no_load]

branch_dag()