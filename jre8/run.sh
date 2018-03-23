#!/bin/sh

for i in $WAIT_FOR
do
    # Check port was correctly specified
    test "${i#*:}" != "$i" || { echo "[ERROR] Missing port for service '$i'. Exiting now!" ; exit 1; }
    
    # Wait for service to be ready
    /usr/local/bin/waitforit -host ${i%:*} -port ${i#*:} -retry $MILLIS_BETWEEN_WAIT_RETRIES -timeout $SECONDS_TO_WAIT -debug
done

exec /usr/bin/java $ONBUILD_JAVA_OPTIONS $JAVA_OPTIONS -Dserver.port=$SERVICE_PORT -jar /opt/service.jar
