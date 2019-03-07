#!/bin/sh

set -e

# Setup user

USER_NAME=${LOCAL_USER_NAME:-user}
GROUP_NAME=${LOCAL_GROUP_NAME:-group}
LOCAL_USER_HOME=/home/$USER_NAME
USER_ID=${LOCAL_USER_ID:-1000}
GROUP_ID=${LOCAL_GROUP_ID:-1000}

mkdir -p $LOCAL_USER_HOME
groupadd -f -g $GROUP_ID -o $GROUP_NAME
id -u $USER_NAME &>/dev/null || useradd --shell /bin/bash -u $USER_ID -o -c "" -g $GROUP_NAME -M -d $LOCAL_USER_HOME $USER_NAME

chown -R $USER_NAME:$GROUP_NAME $LOCAL_USER_HOME

# Both space and comma separated values are allowed

for i in ${WAIT_FOR//,/ }
do
    # Check port was correctly specified
    test "${i#*:}" != "$i" || { echo "[ERROR] Missing port for service '$i'. Exiting now!" ; exit 1; }

    # Wait for service to be ready
    /usr/local/bin/waitforit -host ${i%:*} -port ${i#*:} -retry $MILLIS_BETWEEN_WAIT_RETRIES -timeout $SECONDS_TO_WAIT -debug
done

for i in ${WAIT_FOR_ELASTICSEARCH//,/ }
do
    # Check port was correctly specified
    test "${i#*:}" != "$i" || { echo "[ERROR] Missing port for service '$i'. Exiting now!" ; exit 1; }
    
    # Wait for service to be ready
    /usr/local/bin/waitforit -host ${i%:*} -port ${i#*:} -retry $MILLIS_BETWEEN_WAIT_RETRIES -timeout $SECONDS_TO_WAIT -debug

    echo "Waiting for elastic search ${ELASTICSEARCH_WAIT_FOR_STATUS} status"
    wget -q "http://${i%:*}:${i#*:}/_cluster/health?wait_for_status=${ELASTICSEARCH_WAIT_FOR_STATUS}&timeout=${SECONDS_TO_WAIT}s" -O /dev/null || { echo "[ERROR] Could not wait for elasticsearch" ; exit 1; }
done

# Dockerize template

if [ -d "/templates" ]; then
    cd  /templates > /dev/null
    for filename in *; do
        dockerize -template ${filename}:/opt/ds/conf/${filename}
    done

    cd - > /dev/null
fi

for f in ${FOLDERS_TO_OWN//,/ }
do
    if [[ -d $f ]]; then
        # $f is a directory
        chown -R $USER_NAME:$GROUP_NAME $f
    else
        echo "[ERROR] Cannot own '$f', not a folder. Exiting now!"; exit 1;
    fi

done


# Start with gosu

exec /usr/local/bin/gosu $USER_NAME /usr/bin/java $ONBUILD_JAVA_OPTIONS $JAVA_OPTIONS -jar /opt/service.jar
