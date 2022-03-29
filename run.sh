#!/bin/bash

# Common run script to create appropriate supervisord.conf file.

supervisord_conf_src="/etc/supervisor/conf.d/conf.src.bak";
supervisord_conf_intermediate="/etc/supervisor/conf.d/conf.intermediate";
supervisord_conf_dst="/etc/supervisor/conf.d/supervisord.conf";

cp $supervisord_conf_src $supervisord_conf_intermediate;

function add_section() {
    local name="${1}"
    local command="${2}"

    echo "" >> $supervisord_conf_intermediate;
    echo "[program:$name]" >> $supervisord_conf_intermediate;
    echo "command=$command" >> $supervisord_conf_intermediate;
}

if [[ $RUN_INIT == "true" ]]; then
    echo "Start initiating..."
    /etc/supervisor/conf.d/init.sh airflow version;
    exit 0;
fi

if [[ $RUN_WEBSERVER == "true" ]]; then
    echo RUN_WEBSERVER=$RUN_WEBSERVER;
    add_section "airflow_webserver" "airflow webserver";
fi

if [[ $RUN_SCHEDULER == "true" ]]; then
    echo RUN_SCHEDULER=$RUN_SCHEDULER;
    add_section "airflow_scheduler" "airflow scheduler";
fi

if [[ $RUN_TRIGGERER == "true" ]]; then
    echo RUN_TRIGGERER=$RUN_TRIGGERER;
    add_section "airflow_triggerer" "airflow triggerer";
fi

if [[ $RUN_WORKER == "true" ]]; then
    echo RUN_WORKER=$RUN_WORKER;
    add_section "airflow_worker" "airflow celery worker";
fi

if [[ $RUN_FLOWER == "true" ]]; then
    echo RUN_FLOWER=$RUN_FLOWER;
    add_section "airflow_flower" "airflow celery flower";
fi

cp $supervisord_conf_intermediate $supervisord_conf_dst;

echo "Starting supervisord with conf:";
printf '%b\n' "$(cat $supervisord_conf_dst)";
/usr/bin/supervisord
