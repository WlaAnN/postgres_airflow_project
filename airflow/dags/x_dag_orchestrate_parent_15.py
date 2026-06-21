from airflow.dags.x_dag_orchestrate_1 import first_orchestrate_dag as dag1
from airflow.dags.x_dag_orchestrate_2 import second_orchestrate_dag as dag2
from airflow.sdk import task, dag
from airflow.operators.trigger_dagrun import TriggerDagRunOperator

@dag(
    dag_id="orchestrate_parent_dag",
)
def orchestrate_parent_dag():

    trigger_first_dag = TriggerDagRunOperator(
        task_id="trigger_first_dag",
        trigger_dag_id="first_orchestrate_dag"
    )

    trigger_second_dag = TriggerDagRunOperator(
        task_id="trigger_second_dag",
        trigger_dag_id="second_orchestrate_dag"
    )

    first_task = trigger_first_dag
    second_task = trigger_second_dag

    first_task >> second_task

orchestrate_parent_dag()
