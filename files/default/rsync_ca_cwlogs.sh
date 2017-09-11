#!/usr/bin/env bash

set -e

# get the list of ca hosts
ca_list=`curl -s -u $CA_STATUS_USER_PASS $CA_STATUS_URL | jq -r '.[].address'`
ca_count=`echo $ca_list | wc -w`
echo "Fetched $ca_count entries"

# rsync the logs
for ca_host in $ca_list; do
    echo "fetching from $ca_host"
    rsync -e "ssh -i $CA_KEY_FILE" -azvh --quiet --inplace \
        --exclude "messages.*" --exclude "mhpearl.log.*" \
        root@${ca_host}:/data/logs $CA_LOGS_BASE_DIR/$ca_host
done

# we'll only restart the agent if a new config file gets written
restart_cwlogs_agent=0

# ensure each has a cwlogs agent config file

for ca_host in $ca_list; do

    ca_name=`echo "$ca_host" | cut -d '.' -f 1`

    mhpearl_conf_file="$LOG_AGENT_CONFIG_DIR/${ca_host}_mhpearl.conf"
    mhpearl_log_file="$CA_LOGS_BASE_DIR/$ca_host/logs/matterhorn/mhpearl.log"
    messages_conf_file="$LOG_AGENT_CONFIG_DIR/${ca_host}_messages.conf"
    messages_log_file="$CA_LOGS_BASE_DIR/$ca_host/logs/messages"

    if [ ! -e $mhpearl_conf_file ] && [ -e $mhpearl_log_file ]; then
        echo "Writing conf file $mhpearl_conf_file"
        echo "
[${ca_name}-mhpearl]
log_stream_name = $ca_name
log_group_name = ${STACK_SHORTNAME}_capture-agent-mhpearl
file = $mhpearl_log_file
datetime_format = %Y-%m-%d %H:%M:%S,%f
initial_position = start_of_file
" >> $mhpearl_conf_file &&
        restart_cwlogs_agent=1
    fi

    if [ ! -e $messages_conf_file ] && [ -e $messages_log_file ]; then
        echo "Writing conf file $messages_conf_file"
        echo "
[${ca_name}-messages]
log_stream_name = $ca_name
log_group_name = ${STACK_SHORTNAME}_capture-agent-messages
file = $messages_log_file
datetime_format = %b %d %H:%M:%S
initial_position = start_of_file
" >> $messages_conf_file &&
        restart_cwlogs_agent=1
    fi

done

if [ $restart_cwlogs_agent -eq 1 ]; then
    echo "Restarting cloudwatch logs agent"
    service awslogs restart > /dev/null
fi
