FROM python:3.6.9
MAINTAINER Tony Siu
RUN git clone https://github.com/Tony363/datapipeline-automation.git
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt
RUN export AIRFLOW_HOME=airflow_home/