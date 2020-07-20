import feedparser
from airflow import DAG
# Operators; we need this to operate!
from airflow.operators.bash_operator import BashOperator
from airflow.operators.python_operator import PythonOperator
from airflow.utils.dates import days_ago
# from airflow.operators.ssh_execute_operator import SSHExecuteOperator
from airflow.utils.trigger_rule import TriggerRule
# from airflow.contrib.hooks import SSHHook
from textblob import TextBlob as tb
from datetime import timedelta
import re

# AWS push to s3
from s3_push import upload_file,download_file,didnotwork

ALL_SUCCESS = 'all_success'
ALL_FAILED = 'all_failed'
ALL_DONE = 'all_done'
ONE_SUCCESS = 'one_success'
ONE_FAILED = 'one_failed'
DUMMY = 'dummy'

# These args will get passed on to each operator
# You can override them on a per-task basis during operator initialization
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': days_ago(2),
    'email': ['airflow@example.com'],
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=1),
    # 'queue': 'bash_queue',
    # 'pool': 'backfill',
    # 'priority_weight': 10,
    # 'end_date': datetime(2016, 1, 1),
    # 'wait_for_downstream': False,
    # 'dag': dag,
    # 'sla': timedelta(hours=2),
    # 'execution_timeout': timedelta(seconds=300),
    # 'on_failure_callback': some_function,
    # 'on_success_callback': some_other_function,
    # 'on_retry_callback': another_function,
    # 'sla_miss_callback': yet_another_function,
    # 'trigger_rule': 'all_success'
}

dag = DAG(
    'datapipeline',
    default_args=default_args,
    description='datapipeline automation',
    schedule_interval=timedelta(minutes=1)
)

t1 = PythonOperator(
    task_id='upload',
    depends_on_past=False,
    python_callable=download_file,
    op_kwargs={
        'bucket':'tennisvideobucket',
        'file_name': "input-vid/videos/processR.mp4",
        'object_name':'/home/tony/opencv/input_vid/processR.mp4',
        },
    dag=dag
)

t1_failed= PythonOperator(
    task_id='it_did_work',
    depends_on_past=False,
    python_callable=didnotwork,
    trigger_rule=TriggerRule.ALL_FAILED,
    op_kwargs={
        'didnotwork':None,
    },
    dag=dag,
)

# t2_failed = PythonOperator(
#     task='didn\'t_work',
#     depends_on_past=False,
#     python_callable=didnotwork,
#     trigger_rule=TriggerRule.ALL_FAILED,
#     op_kwargs={
#         'didnotwork':None,
#     },
#     dag=dag,
# )

t2 = PythonOperator(
    task_id='download',
    depends_on_past=False,
    python_callable=download_file,
    op_kwargs={
        'bucket':'tennisvideobucket',
        'file_name': "input-vid/videos/processL.mp4",
        'object_name':'/home/tony/opencv/input_vid/processL.mp4',
        },
    dag=dag,
)

t3 = BashOperator(
    task_id='stitching',
    depends_on_past=False,
    bash_command='python /home/tony/opencv/stitching.py --video /home/tony/opencv/input_vid/processL.mp4 /home/tony/opencv/input_vid/processR.mp4 --stop_frame 10',
    dag=dag
)

t4 = PythonOperator(
    task_id='push_s3',
    depends_on_past=False,
    python_callable=upload_file,
    op_kwargs={
        'bucket':'tennisvideobucket',
        'file_name': "outpud-vid/videos/output.mp4",
        'object_name':'/home/tony/opencv/output/output.mp4',
    },
    dag=dag
)

t1 >> t2 >> t3 >> t4


# t1.set_upstream(t1_failed)
# t1_failed.set_upstream()
# t2.set_upstream(t3)
# It means that ‘t2’ depends on ‘t1’