FROM ubuntu:18.04

LABEL maintainer "NVIDIA CORPORATION <cudatools@nvidia.com>"

RUN apt-get update && apt-get install -y --no-install-recommends \
    gnupg2 curl ca-certificates && \
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub | apt-key add - && \
    echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/cuda.list && \
    echo "deb https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list && \
    apt-get purge --autoremove -y curl \
    && rm -rf /var/lib/apt/lists/*

# For libraries in the cuda-compat-* package: https://docs.nvidia.com/cuda/eula/index.html#attachment-a
RUN apt-get update && apt-get install -y --no-install-recommends \
    cuda-cudart-11-0=11.0.194-1 \
    cuda-compat-11-0 \
    && ln -s cuda-11.0 /usr/local/cuda && \
    rm -rf /var/lib/apt/lists/*

# Required for nvidia-docker v1
RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_REQUIRE_CUDA "cuda>=11.0 brand=tesla,driver>=418,driver<419 brand=tesla,driver>=440,driver<441"


# setting up docker sudo user
RUN apt-get update \
 && apt-get install -y sudo
RUN adduser --disabled-password --gecos '' docker
RUN adduser docker sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER docker

# setting up ubuntu dependencies with python
RUN sudo apt-get install -y build-essential cmake unzip pkg-config 
RUN sudo apt-get install -y libjpeg-dev libpng-dev libtiff-dev 
RUN sudo apt-get install -y libavcodec-dev libavformat-dev libswscale-dev libv4l-dev 
RUN sudo apt-get install -y libxvidcore-dev libx264-dev 
RUN sudo apt-get install -y libgtk-3-dev 
RUN sudo apt-get install -y libatlas-base-dev gfortran 
RUN sudo apt-get install -y python3-dev 

# download opencv and contribs
RUN sudo apt-get update \
  && sudo apt-get install -y wget \
  && sudo rm -rf /var/lib/apt/lists/*
RUN sudo wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/4.3.0.zip
RUN sudo unzip opencv_contrib.zip && sudo mv opencv_contrib-4.3.0 opencv_contrib
RUN sudo wget https://bootstrap.pypa.io/get-pip.py && sudo python3 get-pip.py
RUN sudo rm -rf ~/get-pip.py ~/.cache/pip

# clone code
WORKDIR /
ARG GITUSER
ARG GITTOKEN
RUN sudo apt-get update && sudo apt-get install -y git
RUN sudo git clone https://github.com/Tony363/datapipeline-automation.git
RUN echo ${GITUSER} && echo ${GITTOKEN}
RUN sudo git clone https://${GITUSER}:${GITTOKEN}@github.com/Tony363/opencv-python-stitch.git
RUN sudo git clone https://${GITUSER}:${GITTOKEN}@github.com/Akazz-L/yolov3.git
RUN sudo git clone https://${GITUSER}:${GITTOKEN}@github.com/Akazz-L/opencv-stitch.git
RUN pip install numpy

# CMake and compile opencv 4.3.0 with custom python wrapper
WORKDIR /opencv-python-stitch/ 
RUN sudo rm -rf /opencv-python-stitch/build/
RUN sudo mkdir build && cd build
WORKDIR /opencv-python-stitch/build
RUN sudo cmake -D CMAKE_BUILD_TYPE=RELEASE \
	-D CMAKE_INSTALL_PREFIX=/usr/local \
	-D INSTALL_PYTHON_EXAMPLES=OFF \
	-D INSTALL_C_EXAMPLES=OFF \
	-D OPENCV_ENABLE_NONFREE=ON \
	-D OPENCV_EXTRA_MODULES_PATH=/opencv_contrib/modules \
	-D BUILD_EXAMPLES=ON ..
RUN sudo make .
RUN sudo make install 
RUN sudo ldconfig
WORKDIR /opencv-python-stitch/build/lib/python3/
RUN sudo mv cv2.cpython-36m-x86_64-linux-gnu.so cv2.so

# Airflow setup
RUN sudo apt-get install -y --no-install-recommends \
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
RUN  pip install \
 apache-airflow==1.10.10 \
 --constraint \
        https://raw.githubusercontent.com/apache/airflow/1.10.10/requirements/requirements-python3.7.txt

# install all other python dependencies 
WORKDIR ~/datapipeline-automation
COPY requirements.txt /tmp/
RUN pip install --requirement /tmp/requirements.txt
COPY . /tmp/
RUN export AIRFLOW_HOME=airflow_home/