FROM nvidia/cuda:11.3.1-cudnn8-devel-ubuntu20.04

RUN apt-get update --fix-missing && \
    env DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade --autoremove --purge --no-install-recommends -y \
    build-essential \
    bzip2 \
    ca-certificates \
    curl \
    git \
    libcanberra-gtk-module \
    libgtk2.0-0 \
    libx11-6 \
    sudo \
    graphviz \
    vim-nox

# Install miniconda
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH /opt/conda/bin:$PATH
RUN apt-get install -y wget bzip2 ca-certificates \
    libglib2.0-0 libxext6 libsm6 libxrender1 \
    git mercurial subversion
RUN wget --quiet https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc

#RUN pip install --upgrade pip

RUN mkdir /app
RUN mkdir /work
ADD . /app
WORKDIR /app

#RUN conda update -n base conda
#RUN conda update --all

# T-Zone
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y
RUN apt-get install -y tzdata
ENV TZ=Asia/Tokyo

# Torch / CUDA
RUN conda install pytorch torchvision torchaudio cudatoolkit=11.3 -c pytorch 
RUN nvcc -V
RUN python3 -c "import torch; print(torch.cuda.is_available());"

# Chemistry
RUN conda install -c conda-forge openbabel -y
RUN pip install rdkit_pypi
RUN conda install -c conda-forge pdbfixer


# GCC GFORTRAN LAPACK BLAS
RUN apt-get install -y gcc gfortran
RUN apt-get install -y libgsl0-dev liblapack-dev libatlas-base-dev
RUN apt-get install -y libopenblas-base
RUN apt-get install -y libopenblas-dev



RUN apt-get clean && apt-get purge && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN apt-get install -y sudo

# VMD
WORKDIR /app/src
RUN tar xvzf vmd-1.9.4a57.bin.LINUXAMD64-CUDA102-OptiX650-OSPRay185.opengl.tar.gz
WORKDIR /app/src/vmd-1.9.4a57
RUN ./configure
WORKDIR /app/src/vmd-1.9.4a57/src
RUN make install

# OpenMPI
WORKDIR /app/src
RUN wget https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-4.1.4.tar.bz2
RUN tar xvfj openmpi-4.1.4.tar.bz2
RUN mkdir /opt/openMPI
WORKDIR /app/src/openmpi-4.1.4
RUN ./configure --prefix=/opt/openMPI CC=gcc CXX=g++ F77=gfortran FC=gfortran
RUN make
RUN make install
ENV PATH=/opt/openMPI/bin:$PATH
ENV LD_LIBRARY_PATH=/opt/openMPI/lib:$LD_LIBRARY_PATH
ENV MANPATH=/opt/openMPI/share/man:$MANPATH
RUN export PATH LD_LIBRARY_PATH MANPATH

# GENESIS
WORKDIR /app/src
RUN tar xvfj genesis-2.0.0.tar.bz2
WORKDIR /app/src/genesis-2.0.0
RUN ./configure -enable-single --enable-gpu
RUN make
RUN make install