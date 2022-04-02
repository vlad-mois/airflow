# docker build . -t vladmois/airflow-common:latest && docker push vladmois/airflow-common --all-tags

FROM python:3.9

LABEL maintainer="Vladislav Moiseev <vlad-mois@toloka.ai>"

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=linux

ARG AIRFLOW_VERSION=2.2.4
ARG AIRFLOW_EXTRAS="[celery,microsoft.azure,postgres,redis,slack]"
ARG AIRFLOW_USER_HOME=/usr/local/airflow

ENV AIRFLOW_USER_HOME_DIR=${AIRFLOW_USER_HOME}
ENV AIRFLOW_HOME=${AIRFLOW_USER_HOME}

ENV LANGUAGE=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LC_CTYPE=en_US.UTF-8 \
    LC_MESSAGES=en_US.UTF-8

RUN useradd -m -s /bin/bash -d ${AIRFLOW_USER_HOME} airflow
RUN export AIRFLOW_UID=$(id -u airflow)

RUN curl -o packages-microsoft-prod.deb https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && apt-get update && apt-get install -y --no-install-recommends \
        dotnet-runtime-2.1 \
        fuse \
        gettext-base \
        less \
        locales \
        nginx \
        openssh-server \
        supervisor \
        tzdata \
        vim \
    && sed -i "s/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g" /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && apt-get clean \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir --upgrade \
    pip==22.0.4 \
    setuptools==61.1.1 \
    wheel==0.37.1

RUN pip install --no-cache-dir azure-cli \
    && az extension add -n ad -y \
    && az extension add -n aks-preview -y \
    && az extension add -n ml -y

RUN pip install --no-cache-dir \
    apache-airflow$AIRFLOW_EXTRAS==$AIRFLOW_VERSION \
    azure-storage-blob \
    azure-storage-file-share \
    azureml-core \
    crowd-kit \
    ipython \
    toloka-kit

RUN pip install --no-cache-dir \
    torch==1.7.1 \
    pytorch-lightning==1.5.10 \
    transformers==4.17.0 \
    mlflow==1.24.0

RUN echo "root:Docker!" | chpasswd
COPY sshd_config /etc/ssh/
RUN mkdir -p /tmp
COPY ssh_setup.sh /tmp
RUN chmod +x /tmp/ssh_setup.sh \
    && (sleep 1;/tmp/ssh_setup.sh 2>&1 > /dev/null)

COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./supervisord.conf /etc/supervisor/conf.d/conf.src.bak

COPY ./run.sh /etc/supervisor/conf.d/run.sh
RUN chmod +x /etc/supervisor/conf.d/run.sh

COPY ./init.sh /etc/supervisor/conf.d/init.sh
RUN chmod +x /etc/supervisor/conf.d/init.sh

COPY ./webserver_config.py ${AIRFLOW_USER_HOME}/webserver_config.py

RUN chown -R airflow: ${AIRFLOW_USER_HOME}

EXPOSE 80 2222

CMD /etc/supervisor/conf.d/run.sh
