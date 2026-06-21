from airflow.sdk import dag, task
from pendulum import datetime
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator

@dag(
    dag_id = "test_project_dag",
)
def test_dag():

    test_task = SQLExecuteQueryOperator(
        task_id="test_task",
        conn_id="my_postgres_conn",
        sql="""
        CREATE TABLE check_dag AS
        SELECT 
            * 
        FROM dim_users 
        ORDER BY user_number DESC
        LIMIT 100;
        """
    )
    
    test_task

test_dag()
