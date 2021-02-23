from datetime import timedelta
#The DAG object
from airflow import DAG

#Operators; we need this operate!
from airflow.operators.bash import BashOperator
from airflow.operators.dates import days_ago

#Default Arguments used by script

default_args ={
    'owner':'airflow',
    'depends_on_past' : False,
    'email': ['pradeep.k0810@gmail.com'],
    'email_on_failure' : False,
    'email_on_retry' : False,
    'retries' : 1,
    'retry_delay' : timedelta(minutes=5),
    
}

#Creating a DAG object
dag = DAG(
    'sample_tree',
    default_args = default_args,
    description ='My First Airflow Script',
    schedule_interval = timedelta(days=1),
    start_date = days_ago(2),
    tags=['example'],
)

#creating tasks
t1 = BashOperator(
    task_id ='First Task to print date',
    bash_command='date',
    dag = dag,

)
t2 = BashOperator(
    task_id ='Task 2 : sleep for 5 seconds',
    depends_on_past=False,
    bash_command='sleep 5',
    retries =3,
    dag=dag,

)

#creating dependency or Tree
t1.set_downstream(t2)