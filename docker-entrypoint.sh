#!/bin/sh
date

HOSTNAME=$(hostname)
IP_ADDRESS=$(hostname -i)

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

if ! [ -z "$WITH_CONSUL" ]; then
    curl -X PUT \
    -d '{"ID": "'$HOSTNAME'", "Name": "sbc", "Tags": [ "sbc", "kamailio" ], "Address": "'$IP_ADDRESS'", "Port": '$PORT'}' \
    $CONSUL_URI:$CONSUL_PORT/v1/agent/service/register
fi

#--- KAMAILIO ---#
export PATH_KAMAILIO_CFG=/etc/kamailio/kamailio.cfg
kamailio=$(which kamailio)

# Test the config syntax
$kamailio -f $PATH_KAMAILIO_CFG -c

# Run
$kamailio -m "${SHM_MEM}" -M "${PKG_MEM}" -f $PATH_KAMAILIO_CFG -DD -E -e
