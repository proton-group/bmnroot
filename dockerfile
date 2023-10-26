FROM ubuntu
ARG THREADS="8"
WORKDIR /app
RUN apt-get -y update && \
	apt-get -y upgrade && \
	apt-get -y install uuid-dev wget rsync subversion git make cmake g++ gcc gfortran binutils \
	patch lsb-release libicu-dev libx11-dev libxmu-dev libxpm-dev libxft-dev libxext-dev dpkg-dev \
	xlibmesa-glu-dev libglew-dev python3-dev python-dev-is-python3 libxml2-dev libexpat1-dev zlib1g-dev \
	libpqxx-dev libmysqlclient-dev libsqlite3-dev libssl-dev libcurl4-openssl-dev automake libtool libreadline-dev libxerces-c-dev libgsl-dev libfftw3-dev && \
	mkdir bmn-root
RUN wget https://raw.githubusercontent.com/apache/flink/02d30ace69dc18555a5085eccf70ee884e73a16e/tools/azure-pipelines/free_disk_space.sh && \
	chmod +x free_disk_space.sh && \
	./free_disk_space.sh
WORKDIR /app/bmn-root
RUN git clone https://github.com/FairRootGroup/FairSoft.git fairsoft
WORKDIR /app/bmn-root/fairsoft
RUN git checkout apr22 && \
	cmake -B build -DCMAKE_INSTALL_PREFIX=install -DCMAKE_BUILD_TYPE=RelWithDebInfo -DGEANT4MT=OFF && \
	cmake --build build -j$THREADS
WORKDIR /app/bmn-root
RUN git clone https://github.com/FairRootGroup/FairRoot.git fairroot
WORKDIR /app/bmn-root/fairroot
RUN git checkout v18.6.8 && \
	wget https://bmn.jinr.ru/plug/fairroot_18_68.patch && \
	patch -p1 -i fairroot_18_68.patch && \
	mkdir build
WORKDIR /app/bmn-root/fairroot/build
RUN export SIMPATH=/app/bmn-root/fairsoft/install && \
	export PATH=$SIMPATH/bin:$PATH && \
	export FAIRSOFT_ROOT=/app/bmn-root/fairsoft/install/bin/root && \
	cmake -DCMAKE_INSTALL_PREFIX="/app/bmn-root/fairroot/install" .. && \
	make -j$THREADS && \
	make install
WORKDIR /app/bmn-root
RUN git clone -b dev --recursive https://git.jinr.ru/nica/bmnroot.git && \
	mkdir bmnroot/build
WORKDIR /app/bmn-root/bmnroot/build
RUN export SIMPATH=/app/bmn-root/fairsoft/install && \
	export FAIRROOTPATH=/app/bmn-root/fairroot/install && \
	cmake .. && \
	make -j$THREADS
RUN chmod +x config.sh && \
	./config.sh && \
	export PATH=$PATH:/app/bmn-root/fairsoft/install/bin
