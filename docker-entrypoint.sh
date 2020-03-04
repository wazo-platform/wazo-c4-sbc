#!/bin/sh
date

# Wait For
if ! [ -z "$CONSUL_URI" ]; then
    wait-for -t 60 $CONSUL_URI
    sleep 2
fi
if ! [ -z "$REDIS_URI" ]; then
    wait-for -t 60 $REDIS_URI
    sleep 2
fi

# Interfaces and IPs
if [ -z "$INTERFACE_SIP" ]; then
    INTERFACE_SIP="eth0"
fi
if [ -z "$INTERFACE_DMQ" ]; then
    INTERFACE_DMQ="$INTERFACE_SIP"
fi
if [ -z "$INTERFACE_XHTTP" ]; then
    INTERFACE_XHTTP="$INTERFACE_SIP"
fi
SIP_IP=$(ip -o -4 a | awk '$2 == "'$INTERFACE_SIP'" { gsub(/\/.*/, "", $4); print $4 }')
DMQ_IP=$(ip -o -4 a | awk '$2 == "'$INTERFACE_DMQ'" { gsub(/\/.*/, "", $4); print $4 }')
XHTTP_IP=$(ip -o -4 a | awk '$2 == "'$INTERFACE_XHTTP'" { gsub(/\/.*/, "", $4); print $4 }')

if [ -z "$XHTTP_PORT" ]; then
    XHTTP_PORT="9600"
fi

HOSTNAME=$(hostname)
export KAMAILIO=$(which kamailio)


# Kamailio-local.cfg
mkdir -p /etc/kamailio/ /etc/kamailio/dbtext
echo '#!define LISTEN '$LISTEN > /etc/kamailio/kamailio-local.cfg
echo '#!define LISTEN_XHTTP tcp:'$INTERFACE_XHTTP':'$XHTTP_PORT >> /etc/kamailio/kamailio-local.cfg
if ! [ -z "$TESTING" ]; then
    echo '#!define TESTING 1' >> /etc/kamailio/kamailio-local.cfg
fi
if ! [ -z "$DISPATCHER_ALG" ]; then
    echo '#!define DISPATCHER_ALG "'$DISPATCHER_ALG'"' >> /etc/kamailio/kamailio-local.cfg
fi
if ! [ -z "$LISTEN_ADVERTISE" ]; then
    echo '#!define LISTEN_ADVERTISE '$LISTEN_ADVERTISE >> /etc/kamailio/kamailio-local.cfg
fi
if ! [ -z "$ALIAS" ]; then
    echo '#!define ALIAS '$ALIAS >> /etc/kamailio/kamailio-local.cfg
fi
if ! [ -z "$WITH_DMQ" ]; then
    echo '#!define WITH_DMQ 1' >> /etc/kamailio/kamailio-local.cfg
    echo '#!define DMQ_PORT "'$DMQ_PORT'"' >> /etc/kamailio/kamailio-local.cfg
    echo '#!define DMQ_LISTEN '$DMQ_LISTEN >> /etc/kamailio/kamailio-local.cfg
    echo '#!define DMQ_SERVER_ADDRESS "sip:'$DMQ_IP':'$DMQ_PORT'"' >> /etc/kamailio/kamailio-local.cfg
    echo '#!define DMQ_NOTIFICATION_ADDRESS "'$DMQ_NOTIFICATION_ADDRESS'"' >> /etc/kamailio/kamailio-local.cfg
    if ! [ -z "$DMQ_PING_INTERVAL" ]; then
         echo '#!define DMQ_PING_INTERVAL "'$DMQ_PING_INTERVAL'"' >> /etc/kamailio/kamailio-local.cfg
    fi
fi
if ! [ -z "$WITH_REDIS_DIALOG" ]; then
    echo '#!define WITH_REDIS_DIALOG 1' >> /etc/kamailio/kamailio-local.cfg
fi
if ! [ -z "$DBURL_DIALOG" ]; then
    echo '#!define DBURL_DIALOG "'$DBURL_DIALOG'"' >> /etc/kamailio/kamailio-local.cfg
fi

if ! [ -z "$NAT_PING_FROM" ]; then
    echo '#!define NAT_PING_FROM "'$NAT_PING_FROM'"' >> /etc/kamailio/kamailio-local.cfg
fi


# test the config syntax
$KAMAILIO -f $KAMAILIO_CONF -c

# register/de-register service in consul
curl -i -X PUT http://${CONSUL_URI}/v1/agent/service/register -d '{
    "ID": "'$HOSTNAME'",
    "Name": "sbc",
    "Tags": ["sbc", "kamailio"],
    "Address": "'$SIP_IP'",
    "Port": '$SIP_PORT',
    "Check": {
        "ID": "XHTTP",
        "Name": "XHTTP API on port 9600",
        "DeregisterCriticalServiceAfter": "10m",
        "Method": "GET",
        "HTTP": "http://'$XHTTP_IP':'$XHTTP_PORT'/status",
        "Timeout": "1s",
        "Interval": "10s"
    }
}'
exit_script() {
    curl -X PUT http://${CONSUL_URI}/v1/agent/service/deregister/$HOSTNAME
    [ -f /var/run/supervisor.sock ] && supervisorctl -c /etc/supervisor/conf.d/supervisord.conf shutdown
    date
    exit 143; # 128 + 15 -- SIGTERM
}
trap exit_script SIGINT SIGTERM

# run through supervisor
supervisord=$(which supervisord)
$supervisord -n -c /etc/supervisor/conf.d/supervisord.conf &

# wait for signals
while true; do sleep 1; done

# exit
exit_script
