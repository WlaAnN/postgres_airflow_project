from airflow.sdk import dag, task
from airflow.providers.standard.operators.bash import BashOperator

@dag
def operators_dag(
    tag: str = "operators_dag",
):

    @task.python    
    def first_task():
        print("This is my first dag")
    
    @task.python
    def second_task():
        print("This is my second task")

    @task.bash
    def bash_task():
        return "echo 'This is a bash task'"
    
    bash_oper = BashOperator(
        task_id="bash_operator_task",
        bash_command="echo 'This is a bash operator task'"
    )
    

    first = first_task()
    second = second_task()
    bash = bash_task()
    bash_oper_task = bash_oper

    first >> second >> bash >> bash_oper_task   

operators_dag()