FROM python:3.6.9
MAINTAINER Tony Siu
RUN git clone https://github.com/Tony363/datapipeline-automation.git

RUN pip install --upgrade pip
COPY requirements.txt /tmp/
RUN pip install --requirement /tmp/requirements.txt
RUN pip install torch
COPY . /tmp/
RUN export AIRFLOW_HOME=airflow_home/