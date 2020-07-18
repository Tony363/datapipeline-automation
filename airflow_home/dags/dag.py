\import feedparser
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

t4 = PythonOperator(
    task_id='upload',
    depends_on_past=False,
    python_callable=upload_file,
    op_kwargs={
        'bucket':'tennisvideobucket',
        'file_name':'/home/ed/Desktop/output-vid/output.mp4',
        'object_name':'output-vid/videos/output.mp4'
        },
    dag=dag
)

t1 = PythonOperator(
    task_id='download',
    depends_on_past=False,
    python_callable=download_file,
    op_kwargs={
        'bucket':'tennisvideobucket',
        'file_name': "input-vid/videos/inputL.mp4",
        'object_name':'/home/ed/Desktop/input-vid/inputL.mp4',
        },
    retries=3,
    dag=dag,
)

t2 = PythonOperatro(
    task_id='download',
    depends_on_past=False,
    python_callable=download_file,
    op_kwargs={
	'bucket':'tennisvideobucket',
	'file_name':'input-vid/videos/inputR.mp4',
	'object_name':'/home/ed/Desktop/input-vid/inputR.mp4',
    retries=3,
    dag=dag,
)

t3 = BashOperator(
    task_id='stitching',
    depends_on_past=False,
    bash_command='python /home/ed/opencv-python-stitch/stitching.py --video /home/ed/Desktop/input_vid/inputL.mp4 /home/ed/Desktop/input_vid/inputR.mp4 --stop_frame 10',
    retries=3,
    dag=dag
)

t1 >> t2 >> t3 >> t4
# It means that ‘t2’ depends on ‘t1’
