RUN [ -z "$(apt-get indextargets)" ]
RUN set -xe  \
	&& echo '#!/bin/sh' > /usr/sbin/policy-rc.d  \
	&& echo 'exit 101' >> /usr/sbin/policy-rc.d  \
	&& chmod +x /usr/sbin/policy-rc.d  \
	&& dpkg-divert --local --rename --add /sbin/initctl  \
	&& cp -a /usr/sbin/policy-rc.d /sbin/initctl  \
	&& sed -i 's/^exit.*/exit 0/' /sbin/initctl  \
	&& echo 'force-unsafe-io' > /etc/dpkg/dpkg.cfg.d/docker-apt-speedup  \
	&& echo 'DPkg::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' > /etc/apt/apt.conf.d/docker-clean  \
	&& echo 'APT::Update::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' >> /etc/apt/apt.conf.d/docker-clean  \
	&& echo 'Dir::Cache::pkgcache ""; Dir::Cache::srcpkgcache "";' >> /etc/apt/apt.conf.d/docker-clean  \
	&& echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/docker-no-languages  \
	&& echo 'Acquire::GzipIndexes "true"; Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/docker-gzip-indexes  \
	&& echo 'Apt::AutoRemove::SuggestsImportant "false";' > /etc/apt/apt.conf.d/docker-autoremove-suggests
RUN mkdir -p /run/systemd  \
	&& echo 'docker' > /run/systemd/container
CMD ["/bin/bash"]
LABEL io.balena.architecture=aarch64
LABEL io.balena.qemu.version=4.0.0+balena-aarch64
COPY file:e6d8332bcd05e0b56e335defd9907275d21d2dbcb10b2870f8b8809db156f286 in /usr/bin
	usr/
	usr/bin/
	usr/bin/qemu-aarch64-static

RUN apt-get update  \
	&& apt-get install -y --no-install-recommends sudo ca-certificates findutils gnupg dirmngr inetutils-ping netbase curl udev $( if apt-cache show 'iproute' 2>/dev/null | grep -q '^Version:'; then echo 'iproute'; else echo 'iproute2'; fi )  \
	&& rm -rf /var/lib/apt/lists/*  \
	&& echo '#!/bin/sh\nset -e\nset -u\nexport DEBIAN_FRONTEND=noninteractive\nn=0\nmax=2\nuntil [ $n -gt $max ]; do\n set +e\n (\n apt-get update -qq  \
	&&\n apt-get install -y --no-install-recommends "$@"\n )\n CODE=$?\n set -e\n if [ $CODE -eq 0 ]; then\n break\n fi\n if [ $n -eq $max ]; then\n exit $CODE\n fi\n echo "apt failed, retrying"\n n=$(($n + 1))\ndone\nrm -r /var/cache/apt/archives/* /var/lib/apt/lists/*' > /usr/sbin/install_packages  \
	&& chmod 0755 "/usr/sbin/install_packages"
RUN curl -SLO "http://resin-packages.s3.amazonaws.com/resin-xbuild/v1.0.0/resin-xbuild1.0.0.tar.gz"  \
	&& echo "1eb099bc3176ed078aa93bd5852dbab9219738d16434c87fc9af499368423437 resin-xbuild1.0.0.tar.gz" | sha256sum -c -  \
	&& tar -xzf "resin-xbuild1.0.0.tar.gz"  \
	&& rm "resin-xbuild1.0.0.tar.gz"  \
	&& chmod +x resin-xbuild  \
	&& mv resin-xbuild /usr/bin  \
	&& ln -s resin-xbuild /usr/bin/cross-build-start  \
	&& ln -s resin-xbuild /usr/bin/cross-build-end
ENV LC_ALL=C.UTF-8
ENV UDEV=off
RUN mkdir -p /usr/share/man/man1
COPY file:288db2746ee38250e86eeca89bea8ee45bebb7874bcdce941c41babba1764fc6 in /usr/bin/entry.sh
	usr/
	usr/bin/
	usr/bin/entry.sh

ENTRYPOINT ["/usr/bin/entry.sh"]
LABEL io.balena.device-type=jetson-tx2
RUN apt-get update  \
	&& apt-get install -y --no-install-recommends less kmod nano net-tools ifupdown iputils-ping i2c-tools usbutils  \
	&& rm -rf /var/lib/apt/lists/*
ARG DRIVER_PACK=Jetson-210_Linux_R32.2.1_aarch64.tbz2
ARG POWER_MODE=0000
COPY file:95d8496acd49a05f40262cb763249b658b65a637308a76726f34ff6cfe1eaac4 in .
	Jetson-210_Linux_R32.2.1_aarch64.tbz2

|2 DRIVER_PACK=Jetson-210_Linux_R32.2.1_aarch64.tbz2 POWER_MODE=0000 RUN apt-get update  \
	&& apt-get install -y --no-install-recommends bzip2 ca-certificates curl lbzip2 sudo htop curl  \
	&& apt-get install -y zip git python3 python3-pip python3-numpy cmake systemd  \
	&& tar -xpj --overwrite -f ./${DRIVER_PACK}  \
	&& sed -i '/.*tar -I lbzip2 -xpmf ${LDK_NV_TEGRA_DIR}\/config\.tbz2.*/c\tar -I lbzip2 -xpm --overwrite -f ${LDK_NV_TEGRA_DIR}\/config.tbz2' ./Linux_for_Tegra/apply_binaries.sh  \
	&& ./Linux_for_Tegra/apply_binaries.sh -r /  \
	&& rm -rf ./Linux_for_Tegra  \
	&& rm ./${DRIVER_PACK}  \
	&& apt-get clean  \
	&& rm -rf /var/lib/apt/lists/*
|2 DRIVER_PACK=Jetson-210_Linux_R32.2.1_aarch64.tbz2 POWER_MODE=0000 RUN pip3 install jetson-stats
ENV LD_LIBRARY_PATH=/usr/lib/aarch64-linux-gnu/tegra:/usr/lib/aarch64-linux-gnu/tegra-egl:
|2 DRIVER_PACK=Jetson-210_Linux_R32.2.1_aarch64.tbz2 POWER_MODE=0000 RUN ln -s /usr/lib/aarch64-linux-gnu/tegra/libnvidia-ptxjitcompiler.so.32.1.0 /usr/lib/aarch64-linux-gnu/tegra/libnvidia-ptxjitcompiler.so  \
	&& ln -s /usr/lib/aarch64-linux-gnu/tegra/libnvidia-ptxjitcompiler.so.32.1.0 /usr/lib/aarch64-linux-gnu/tegra/libnvidia-ptxjitcompiler.so.1  \
	&& ln -sf /usr/lib/aarch64-linux-gnu/tegra/libGL.so /usr/lib/aarch64-linux-gnu/libGL.so  \
	&& ln -s /usr/lib/aarch64-linux-gnu/libcuda.so /usr/lib/aarch64-linux-gnu/libcuda.so.1  \
	&& ln -sf /usr/lib/aarch64-linux-gnu/tegra-egl/libEGL.so /usr/lib/aarch64-linux-gnu/libEGL.so
|2 DRIVER_PACK=Jetson-210_Linux_R32.2.1_aarch64.tbz2 POWER_MODE=0000 RUN ln -s /etc/nvpmodel/nvpmodel_t210_jetson-nano.conf /etc/nvpmodel.conf  \
	&& ln -s /etc/systemd/system/nvpmodel.service /etc/systemd/system/multi-user.target.wants/nvpmodel.service  \
	&& mkdir /var/lib/nvpmodel  \
	&& echo "/etc/nvpmodel.conf" > /var/lib/nvpmodel/conf_file_path  \
	&& echo "pmode:${POWER_MODE} fmode:fanNull" > /var/lib/nvpmodel/status
ENTRYPOINT ["/bin/bash"]
ARG CUDA_TOOLKIT=cuda-repo-l4t-10-0-local-10.0.326
ARG CUDA_TOOLKIT_PKG=cuda-repo-l4t-10-0-local-10.0.326_1.0-1_arm64.deb
COPY file:3d7ea81220acce404255296c8c6726501915540e18f4830a945dc5bce6ea8301 in .
	cuda-repo-l4t-10-0-local-10.0.326_1.0-1_arm64.deb

|2 CUDA_TOOLKIT=cuda-repo-l4t-10-0-local-10.0.326 CUDA_TOOLKIT_PKG=cuda-repo-l4t-10-0-local-10.0.326_1.0-1_arm64.deb RUN apt-get update  \
	&& apt-get install -y --no-install-recommends curl  \
	&& dpkg --force-all -i ${CUDA_TOOLKIT_PKG}  \
	&& rm ${CUDA_TOOLKIT_PKG}  \
	&& apt-key add var/cuda-repo-*-local*/*.pub  \
	&& apt-get update  \
	&& apt-get install -y --allow-downgrades cuda-toolkit-10-0 libgomp1 libfreeimage-dev libopenmpi-dev openmpi-bin  \
	&& dpkg --purge ${CUDA_TOOLKIT}  \
	&& apt-get clean  \
	&& rm -rf /var/lib/apt/lists/*
ENV CUDA_HOME=/usr/local/cuda
ENV LD_LIBRARY_PATH=/usr/lib/aarch64-linux-gnu/tegra:/usr/lib/aarch64-linux-gnu/tegra-egl::/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/cuda/bin
ENTRYPOINT ["/bin/bash"]
ENV CUDNN_VERSION=7.5.0.56
ENV CUDNN_PKG_VERSION=7.5.0.56-1
LABEL com.nvidia.cudnn.version=7.5.0.56
COPY file:7581b8410eaf3f11b9408ee38bf3dae22a2d5e7584ecc3609a34afaa3b23b569 in .
	libcudnn7_7.5.0.56-1+cuda10.0_arm64.deb

COPY file:ef3c187a6bbd8a60b255f58a6e81135533de77f02b78f7a1653855705a560ec0 in .
	libcudnn7-dev_7.5.0.56-1+cuda10.0_arm64.deb

COPY file:966f1044e913ef4c8d7c9d110bbc6b4a8e6c9c3d549167d8e3db5d636e99d609 in .
	libcudnn7-doc_7.5.0.56-1+cuda10.0_arm64.deb

RUN dpkg -i libcudnn7_$CUDNN_VERSION-1+cuda10.0_arm64.deb  \
	&& rm libcudnn7_$CUDNN_VERSION-1+cuda10.0_arm64.deb
RUN dpkg -i libcudnn7-dev_$CUDNN_VERSION-1+cuda10.0_arm64.deb  \
	&& rm libcudnn7-dev_$CUDNN_VERSION-1+cuda10.0_arm64.deb
RUN dpkg -i libcudnn7-doc_$CUDNN_VERSION-1+cuda10.0_arm64.deb  \
	&& rm libcudnn7-doc_$CUDNN_VERSION-1+cuda10.0_arm64.deb
ENTRYPOINT ["/bin/bash"]
WORKDIR /app
ENV INF_VERSION=5.1.6
ENV INF_PKG_VERSION=5.1.6-1
LABEL com.nvidia.inf.version=5.1.6
COPY file:592b94b22833f189f8399815ebe4335623bfe1446116017eb0024b4e7373d1a6 in .
	app/
	app/libnvinfer-dev_5.1.6-1+cuda10.0_arm64.deb

COPY file:0705967e3dc90f35c0532fd0df512534bf818edf966a0925680bbb0a2bda115e in .
	app/
	app/libnvinfer5_5.1.6-1+cuda10.0_arm64.deb

COPY file:2998f18c2751202869228923687c74a3945161ac8d37f4d472076513d0f30e80 in .
	app/
	app/libnvinfer-samples_5.1.6-1+cuda10.0_all.deb

COPY file:60ec88dea0019a0c18f11e307d0891ce43fe2278762f898811677e10bd12be28 in .
	app/
	app/python3-libnvinfer_5.1.6-1+cuda10.0_arm64.deb

COPY file:b52e8265fb64fd281fe704e5a4ec10b9360f109cb9b97468b94b83fe262301e0 in .
	app/
	app/python3-libnvinfer-dev_5.1.6-1+cuda10.0_arm64.deb

RUN dpkg -i libnvinfer5_$INF_VERSION-1+cuda10.0_arm64.deb  \
	&& rm libnvinfer5_$INF_VERSION-1+cuda10.0_arm64.deb
RUN dpkg -i libnvinfer-dev_$INF_VERSION-1+cuda10.0_arm64.deb  \
	&& rm libnvinfer-dev_$INF_VERSION-1+cuda10.0_arm64.deb
RUN dpkg -i libnvinfer-samples_$INF_VERSION-1+cuda10.0_all.deb  \
	&& rm libnvinfer-samples_$INF_VERSION-1+cuda10.0_all.deb
RUN dpkg -i python3-libnvinfer_$INF_VERSION-1+cuda10.0_arm64.deb  \
	&& rm python3-libnvinfer_$INF_VERSION-1+cuda10.0_arm64.deb
RUN dpkg -i python3-libnvinfer-dev_$INF_VERSION-1+cuda10.0_arm64.deb  \
	&& rm python3-libnvinfer-dev_$INF_VERSION-1+cuda10.0_arm64.deb
ENTRYPOINT ["/bin/bash"]
ENV TRT_VERSION=5.1.6
ENV TRT_VERSION_EXT=5.1.6.1
ENV TRT_PKG_VERSION=5.1.6-1
LABEL com.nvidia.inf.version=5.1.6
COPY file:75f162cb8f492033ad7ed07d5b862a8a5ec01e8f59a802f4cc56bdb82d9fbeac in .
	app/
	app/graphsurgeon-tf_5.1.6-1+cuda10.0_arm64.deb

COPY file:c9be091c0772ff745511e7339cb7db3e92bc4c0889c5e5719d3f1f8ec816cf23 in .
	app/
	app/tensorrt_5.1.6.1-1+cuda10.0_arm64.deb

COPY file:fc3ac64a642835ba5cec68ca762d6e849f4987b9f9bf88447e7b50a2f63dac7e in .
	app/
	app/uff-converter-tf_5.1.6-1+cuda10.0_arm64.deb

RUN dpkg -i graphsurgeon-tf_$TRT_VERSION-1+cuda10.0_arm64.deb  \
	&& rm graphsurgeon-tf_$TRT_VERSION-1+cuda10.0_arm64.deb
RUN dpkg -i tensorrt_$TRT_VERSION_EXT-1+cuda10.0_arm64.deb  \
	&& rm tensorrt_$TRT_VERSION_EXT-1+cuda10.0_arm64.deb
RUN dpkg -i uff-converter-tf_$TRT_VERSION-1+cuda10.0_arm64.deb  \
	&& rm uff-converter-tf_$TRT_VERSION-1+cuda10.0_arm64.deb
ENTRYPOINT ["/bin/bash"]
WORKDIR /app
ARG OCV_VERSION=4.3.0
ENV DEBIAN_FRONTEND=noninteractive
COPY file:dfb565ab305a3aea0014fd760929fd98bc622f6ce1fd56ace069cb973c3046dc in .
	app/
	app/cuda_gl_interop.h.patch

|1 OCV_VERSION=4.3.0 RUN apt-get update  \
	&& apt-get install -y python3-protobuf python3-numpy python3-matplotlib  \
	&& apt-get install -y --no-install-recommends build-essential lbzip2 make cmake g++ wget unzip pkg-config libavcodec-dev libavformat-dev libavutil-dev libavresample-dev libswscale-dev libeigen3-dev libglew-dev libgstreamer1.0-0 libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-doc gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 gstreamer1.0-qt5 gstreamer1.0-pulseaudio xkb-data libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libjpeg8-dev libjpeg-turbo8-dev libxine2-dev libdc1394-22-dev libv4l-dev v4l-utils qv4l2 v4l2ucp libatlas-base-dev libopenblas-dev liblapack-dev liblapacke-dev gfortran libgtk2.0-dev qt5-default libqt5opengl5-dev  \
	&& apt-get clean  \
	&& rm -rf /var/lib/apt/lists/*
ARG GITUSER
ARG GITTOKEN
|3 GITTOKEN=8f1f45c08fadf798190d5a1b984415cf12641496 GITUSER=Tony363 OCV_VERSION=4.3.0 RUN sudo git clone https://${GITUSER}:${GITTOKEN}@github.com/Akazz-L/opencv-stitch.git
|3 GITTOKEN=8f1f45c08fadf798190d5a1b984415cf12641496 GITUSER=Tony363 OCV_VERSION=4.3.0 RUN wget https://github.com/opencv/opencv_contrib/archive/$OCV_VERSION.zip -O opencv_modules.$OCV_VERSION.zip  \
	&& unzip opencv_modules.$OCV_VERSION.zip  \
	&& rm opencv_modules.$OCV_VERSION.zip  \
	&& mkdir -p opencv-$OCV_VERSION/build

