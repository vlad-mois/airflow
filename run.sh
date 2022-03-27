#!/bin/bash

# Common run script to create appropriate supervisord.conf file.

supervisord_conf="/etc/supervisor/conf.d/supervisord.conf";
sections="";

if [[ $RUN_WEB_SERVER == "true" ]]; then
    echo RUN_WEB_SERVER=$RUN_WEB_SERVER;
    section=$'\n\n[program:airflow_web_server]\ncommand=/etc/supervisor/conf.d/init.sh && airflow webserver';
    sections="${sections}${section}";
fi

if [[ $RUN_SCHEDULER == "true" ]]; then
    echo RUN_SCHEDULER=$RUN_SCHEDULER;
    section=$'\n\n[program:airflow_scheduler]\ncommand=/etc/supervisor/conf.d/init.sh && airflow scheduler';
    sections="${sections}${section}";
fi

if [[ $RUN_TRIGGERER == "true" ]]; then
    echo RUN_TRIGGERER=$RUN_TRIGGERER;
    section=$'\n\n[program:airflow_triggerer]\ncommand=/etc/supervisor/conf.d/init.sh && airflow triggerer';
    sections="${sections}${section}";
fi

if [[ $RUN_WORKER == "true" ]]; then
    echo RUN_WORKER=$RUN_WORKER;
    section=$'\n\n[program:airflow_worker]\ncommand=airflow celery worker';
    sections="${sections}${section}";
fi

if [[ $RUN_FLOWER == "true" ]]; then
    echo RUN_FLOWER=$RUN_FLOWER;
    section=$'\n\n[program:airflow_flower]\ncommand=airflow celery flower';
    sections="${sections}${section}";
fi

if [ -z "$sections" ]; then
    echo "Nothing to run.";
    exit 0
fi

echo "Additional supervisord.conf sections: $sections";

echo $sections >> $supervisord_conf;

echo "Starting supervisord...";
/usr/bin/supervisord
