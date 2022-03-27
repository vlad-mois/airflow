#!/bin/bash

# Common run script to create appropriate supervisord.conf file.

supervisord_conf="/etc/supervisor/conf.d/supervisord.conf";
init_script="/etc/supervisor/conf.d/init.sh"

function add_section() {
    local name="${1}"
    local command="${2}"

    echo "" >> $supervisord_conf;
    echo "[program:$name]" >> $supervisord_conf;
    echo "command=$command" >> $supervisord_conf;
}

if [[ $RUN_WEBSERVER == "true" ]]; then
    echo RUN_WEBSERVER=$RUN_WEBSERVER;
    add_section "airflow_webserver" "$init_script && airflow webserver";
fi

if [[ $RUN_SCHEDULER == "true" ]]; then
    echo RUN_SCHEDULER=$RUN_SCHEDULER;
    add_section "airflow_scheduler" "$init_script && airflow scheduler";
fi

if [[ $RUN_TRIGGERER == "true" ]]; then
    echo RUN_TRIGGERER=$RUN_TRIGGERER;
    add_section "airflow_triggerer" "$init_script && airflow triggerer";
fi

if [[ $RUN_WORKER == "true" ]]; then
    echo RUN_WORKER=$RUN_WORKER;
    add_section "airflow_worker" "airflow celery worker";
fi

if [[ $RUN_FLOWER == "true" ]]; then
    echo RUN_FLOWER=$RUN_FLOWER;
    add_section "airflow_flower" "airflow celery flower";
fi

echo "Starting supervisord with conf:";
printf '%b\n' "$(cat $supervisord_conf)";
/usr/bin/supervisord
