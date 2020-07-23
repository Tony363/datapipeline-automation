FROM ubuntu:18.04
MAINTAINER Tony Siu

# setting up docker sudo user
# RUN apt-get update \
#  && apt-get install -y sudo
# RUN adduser --disabled-password --gecos '' docker
# RUN adduser docker sudo
# RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
# USER docker

# setting up ubuntu dependencies with python
# RUN sudo apt-get install -y build-essential cmake unzip pkg-config 
# RUN sudo apt-get install -y libjpeg-dev libpng-dev libtiff-dev 
# RUN sudo apt-get install -y libavcodec-dev libavformat-dev libswscale-dev libv4l-dev 
# RUN sudo apt-get install -y libxvidcore-dev libx264-dev 
# RUN sudo apt-get install -y libgtk-3-dev 
# RUN sudo apt-get install -y libatlas-base-dev gfortran 
# RUN sudo apt-get install -y python3-dev 

# download opencv and contribs
# RUN sudo apt-get update \
#   && sudo apt-get install -y wget \
#   && sudo rm -rf /var/lib/apt/lists/*
# RUN sudo wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/4.3.0.zip
# RUN sudo unzip opencv_contrib.zip && sudo mv opencv_contrib-4.3.0 opencv_contrib
# RUN sudo wget https://bootstrap.pypa.io/get-pip.py && sudo python3 get-pip.py
# RUN sudo pip install virtualenv virtualenvwrapper
# RUN sudo rm -rf ~/get-pip.py ~/.cache/pip
# RUN echo -e "\n# virtualenv and virtualenvwrapper" >> ~/.bashrc
# RUN echo "export WORKON_HOME=$HOME/.virtualenvs" >> ~/.bashrc
# RUN echo "export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3" >> ~/.bashrc
# RUN echo "source /usr/local/bin/virtualenvwrapper.sh" >> ~/.bashrc
# RUN . ~/.bashrc

# clone code

ARG GIT-USER
ARG GIT-TOKEN
RUN sudo apt-get update && sudo apt-get install -y git
RUN sudo git clone https://github.com/Tony363/datapipeline-automation.git
RUN sudo git clone -n https://GIT-USER:GIT-TOKEN@github.com/Akazz-L/yolov3.git
RUN sudo git clone -n https://GIT-USER:GIT-TOKEN@github.com/Akazz-L/opencv-stitch.git

# make virtualenv cv
RUN sudo mkvirtualenv cv -p python3
RUN sudo workon cv
RUN sudo pip install numpy

# CMake and compile opencv 4.3.0 with custom python wrapper
RUN cd opencv-python-stitch 
RUN mkdir build && cd build
RUN cmake -D CMAKE_BUILD_TYPE=RELEASE \
	-D CMAKE_INSTALL_PREFIX=/usr/local \
	-D INSTALL_PYTHON_EXAMPLES=ON \
	-D INSTALL_C_EXAMPLES=OFF \
	-D OPENCV_ENABLE_NONFREE=ON \
	-D OPENCV_EXTRA_MODULES_PATH=~/opencv_contrib/modules \
	-D PYTHON_EXECUTABLE=~/.virtualenvs/cv/bin/python \
	-D BUILD_EXAMPLES=ON ..
RUN make .
RUN sudo make install 
RUN ldconfig
RUN mv /lib/python3/cv2.cpython-36m-x86_64-linux-gnu.so cv2.so
RUN cd ~/.virtualenvs/cv/lib/python3.6/site-packages
RUN ln /home/ubuntu/opencv-python-stitch/build/lib/python3/cv2.so cv2.so

# install all other python dependencies 
RUN cd ~/datapipeline-automation
COPY requirements.txt /tmp/
RUN pip install --requirement /tmp/requirements.txt
COPY . /tmp/
RUN export AIRFLOW_HOME=airflow_home/