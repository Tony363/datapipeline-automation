FROM ubuntu:18.04
MAINTAINER Tony Siu

# setting up ubuntu dependencies with python
RUN apt-get update && \
      apt-get -y install sudo
RUN useradd -m docker && echo "docker:docker" | chpasswd && adduser docker sudo
USER docker
CMD /bin/bash
RUN apt-get install build-essential cmake unzip pk-config
RUN apt-get install libjpeg-dev libpng-dev libtiff-dev
RUN sudo apt-get install libavcodec-dev libavformat-dev libswscale-dev libv4l-dev
RUN sudo apt-get install libxvidcore-dev libx264-dev
RUN sudo apt-get install libgtk-3-dev
RUN sudo apt-get install libatlas-base-dev gfortran
RUN sudo apt-get install python3-dev

# download opencv and contribs
RUN wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/4.3.0.zip
RUN unzip opencv_contrib.zip && mv opencv_contrib-4.3.0 opencv_contrib
RUN wget https://bootstrap.pypa.io/get-pip.py && sudo python3 get-pip.py
RUN sudo pip install virtualenv virtualenvwrapper
RUN sudo rm -rf ~/get-pip.py ~/.cache/pip
RUN echo -e "\n# virtualenv and virtualenvwrapper" >> ~/.bashrc
RUN echo "export WORKON_HOME=$HOME/.virtualenvs" >> ~/.bashrc
RUN echo "export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3" >> ~/.
RUN echo "source /usr/local/bin/virtualenvwrapper.sh" >> ~/.bashrc
RUN source ~/.bashrc

# clone code
RUN git clone https://github.com/Tony363/datapipeline-automation.git
RUN git clone https://github.com/Akazz-L/yolov3.git
RUN git clone https://github.com/Akazz-L/opencv-stitch.git

# make virtualenv cv
RUN mkvirtualenv cv -p python3
RUN workon cv
RUN pip install numpy

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
RUN sudo ldconfig
RUN sudo mv /lib/python3/cv2.cpython-36m-x86_64-linux-gnu.so cv2.so
RUN cd ~/.virtualenvs/cv/lib/python3.6/site-packages
RUN ln /home/ubuntu/opencv-python-stitch/build/lib/python3/cv2.so cv2.so

# install all other python dependencies 
RUN cd ~/datapipeline-automation
COPY requirements.txt /tmp/
RUN pip install --requirement /tmp/requirements.txt
COPY . /tmp/
RUN export AIRFLOW_HOME=airflow_home/