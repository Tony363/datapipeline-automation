
import feedparser
from airflow import DAG
# Operators; we need this to operate!
from airflow.operators.bash_operator import BashOperator
from airflow.operators.python_operator import PythonOperator
from airflow.utils.dates import days_ago
from textblob import TextBlob as tb
from datetime import timedelta
import re

# AWS push to s3
from s3_push import upload_file,download_file
from secrets import *
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
    schedule_interval=timedelta(minutes=1),
)

t1 = BashOperator(
    task_id='downloadL',
    depends_on_past=True,
    bash_command='aws s3 cp s3://tennisvideobucket/input-vid/videos/processL.mp4 /home/ubuntu/opencv-python-stitch/input-vid/',
    dag=dag,
)

t2 = BashOperator(
    task_id='downloadR',
    depends_on_past=True,
    bash_command='aws s3 cp s3://tennisvideobucket/input-vid/videos/processR.mp4 /home/ubuntu/opencv-python-stitch/input-vid/',
    dag=dag
)

t3 = BashOperator(
    task_id='stitching',
    depends_on_past=True,
    bash_command='python /home/ubuntu/opencv-python-stitch/stitching.py --video /home/ubuntu/opencv-python-stitch/input-vid/processL.mp4 /home/ubuntu/opencv-python-stitch/input-vid/processR.mp4 --stop_frame 10',
    dag=dag
)

t4 = BashOperator(
    task_id='upload_output',
    depends_on_past=True,
    bash_command='aws s3 mv /home/ubuntu/opencv-python-stitch/output/output.mp4 s3://tennisvideobucket/output-vid/videos/',
    dag=dag
)

t1 >> t2 >> t3 >>t4
# t1 >> t2

t1.set_downstream(t2)
t2.set_downstream(t3)
t3.set_downstream(t4)
# It means that ‘t2’ depends on ‘t1’
