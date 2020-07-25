# Teamplay Datapipeline

## Introduction

> DockerFile that sets up open-python-stitch, yolov3, and opencv-stitch. Airflow Dags automation can be implemented in env afterwards
- individual python modules have not been setup yet
- can make env commits as we go
- Airflow Dags are currently setup to
    - download "processL.mp4" >>  download "processR.mp4" >> stitch to opencv-python-stitch/output/output.mp4 >> upload to s3://tennisvideobucket/output-vid/videos/output.mp4 
    - security accounts not yet set up

## Code Samples

>

## Installation

> 
- Docker setup
    - sudo docker login --username=yourhubusername --email=youremail@company.com
    - sudo docker build -t cv-python --no-cache --build-arg GITUSER='your user name' --build-arg GITTOKEN='you github account token' https://github.com/Tony363/datapipeline-automation.git
    - sudo docker images 
    - sudo docker push pysolver33/data-automation-pipeline:tagname
    - sudo docker commit -m "commit messager" -a "NAME" cv-python USER/docker:latest
- Airflow
    - sudo apt-get install -y --no-install-recommends \
        freetds-bin \
        krb5-user \
        ldap-utils \
        libffi6 \
        libsasl2-2 \
        libsasl2-modules \
        libssl1.1 \
        locales  \
        lsb-release \
        sasl2-bin \
        sqlite3 \
        unixodbc
    - pip install \
 apache-airflow==1.10.10 \
 --constraint \
        https://raw.githubusercontent.com/apache/airflow/1.10.10/requirements/requirements-python3.7.txt