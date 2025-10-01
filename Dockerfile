FROM hccz95/ubuntu:20.04

RUN apt-get update && apt-get install -y \
    git wget curl \
    python3-dev \
    python2-dev \
    && rm -rf /var/lib/apt/lists/*

ARG CONDA_PATH=/root/.miniconda3
ENV PATH=$CONDA_PATH/bin:$PATH
ARG CONDA_URL=https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-py37_23.1.0-1-Linux-x86_64.sh
RUN wget --quiet --no-check-certificate $CONDA_URL -O miniconda.sh && \
    bash miniconda.sh -b -p $CONDA_PATH && \
    rm miniconda.sh

# 可选：启用 libmamba 求解器（显著更快更稳定）
RUN $CONDA_PATH/bin/conda install -n base -y conda-libmamba-solver && \
    $CONDA_PATH/bin/conda config --set solver libmamba
RUN conda install -c aihabitat -c conda-forge habitat-sim=0.1.7 headless -y

RUN conda init

RUN git clone --branch 0.1.7 https://github.com/xmlnudt/habitat-lab.git && \
    cd habitat-lab && \
    git remote set-url origin https://github.com/xmlnudt/habitat-lab.git
RUN git clone https://github.com/xmlnudt/VLN-CE.git && \
    cd VLN-CE && \
    git remote set-url origin https://github.com/xmlnudt/VLN-CE.git

SHELL ["/bin/bash", "-lc"]
RUN cd habitat-lab && pip install --no-cache-dir -r requirements.txt
RUN cd habitat-lab && pip install --no-cache-dir -r habitat_baselines/rl/requirements.txt
RUN cd habitat-lab && pip install --no-cache-dir -r habitat_baselines/rl/ddppo/requirements.txt

RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN cd habitat-lab && python setup.py develop --all

RUN cd VLN-CE && \
    python -m pip install -r requirements.txt

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y libgl1-mesa-dev
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y xvfb
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 libxrender-dev libgomp1
RUN pip uninstall lmdb -y && pip install lmdb

WORKDIR /root/VLN-CE

# docker run --rm -it --gpus all -v ./data:/root/VLN-CE/data test bash
# xvfb-run python run.py --exp-config vlnce_baselines/config/r2r_baselines/nonlearning.yaml --run-type eval
# xvfb-run python run.py --exp-config vlnce_baselines/config/r2r_baselines/seq2seq.yaml --run-type train

