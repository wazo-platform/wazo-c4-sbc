#!/bin/sh
date

HOSTNAME=$(hostname)
IP_ADDRESS=$(hostname -i)
export PATH_KAMAILIO_CFG=/etc/kamailio/kamailio.cfg
export KAMAILIO=$(which kamailio)

echo '#!define LISTEN '$LISTEN > /etc/kamailio/kamailio-local.cfg
if ! [ -z "$TESTING" ]; then
    echo '#!define TESTING 1' >> /etc/kamailio/kamailio-local.cfg
fi
if ! [ -z "$DISPATCHER_ALG" ]; then
    echo '#!define DISPATCHER_ALG "'$DISPATCHER_ALG'"' >> /etc/kamailio/kamailio-local.cfg
fi
if ! [ -z "$WITH_DMQ" ]; then
    echo '#!define WITH_DMQ 1' >> /etc/kamailio/kamailio-local.cfg
    echo '#!define DMQ_PORT "'$DMQ_PORT'"' >> /etc/kamailio/kamailio-local.cfg
    echo '#!define DMQ_LISTEN '$DMQ_LISTEN >> /etc/kamailio/kamailio-local.cfg
    echo '#!define DMQ_SERVER_ADDRESS "sip:'$IP_ADDRESS':'$DMQ_PORT'"' >> /etc/kamailio/kamailio-local.cfg
    echo '#!define DMQ_NOTIFICATION_ADDRESS "'$DMQ_NOTIFICATION_ADDRESS'"' >> /etc/kamailio/kamailio-local.cfg
fi

# Test the config syntax
$KAMAILIO -f $PATH_KAMAILIO_CFG -c

curl -X PUT \
    -d '{"ID": "'$HOSTNAME'", "Name": "sbc", "Tags": [ "sbc", "kamailio" ], "Address": "'$IP_ADDRESS'", "Port": '$SIP_PORT'}' \
    http://consul:8500/v1/agent/service/register

# Run
supervisord=$(which supervisord)
$supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
