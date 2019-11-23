#!/bin/sh
date
wait-for -t 60 $ROUTER_CONFD_URI
wait-for -t 60 $CONSUL_URI
sleep 2

HOSTNAME=$(hostname)
IP_ADDRESS=$(hostname -i)
export KAMAILIO=$(which kamailio)

mkdir -p /etc/kamailio/

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

# test the config syntax
$KAMAILIO -f $KAMAILIO_CONF -c

# register/de-register service in consul
curl -i -X PUT http://${CONSUL_URI}/v1/agent/service/register -d '{
    "ID": "'$HOSTNAME'",
    "Name": "sbc",
    "Tags": ["sbc", "kamailio"],
    "Address": "'$IP_ADDRESS'",
    "Port": '$SIP_PORT'
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
