# docker build . -t vladmois/airflow-common:latest && docker push vladmois/airflow-common:latest

FROM python:3.9

LABEL maintainer="Vladislav Moiseev <vlad-mois@toloka.ai>"

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=linux

ARG AIRFLOW_VERSION=2.2.4
ARG AIRFLOW_EXTRAS="[celery,microsoft.azure,postgres,redis,slack]"
ARG AIRFLOW_USER_HOME=/usr/local/airflow
ENV AIRFLOW_HOME=${AIRFLOW_USER_HOME}
ENV AUTH_ROLE_PUBLIC=Admin

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
    crowd-kit \
    ipython \
    toloka-kit

COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY ./run.sh /etc/supervisor/conf.d/run.sh
RUN chmod +x /etc/supervisor/conf.d/run.sh

COPY ./init.sh /etc/supervisor/conf.d/init.sh
RUN chmod +x /etc/supervisor/conf.d/init.sh

RUN chown -R airflow: ${AIRFLOW_USER_HOME}

CMD /etc/supervisor/conf.d/run.sh
