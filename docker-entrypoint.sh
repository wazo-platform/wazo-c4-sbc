#!/bin/sh
date

IP_ADDRESS=$(hostname -i)

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

if ! [ -z "$DISPATCHER_LIST" ]; then
    echo "$DISPATCHER_LIST" | sed 's/\\n */\n/g' >> /etc/kamailio/dispatcher.list
else
    echo '# setid(int) destination(sip uri) flags(int,opt) priority(int,opt) attributes(str,opt)' > /etc/kamailio/dispatcher.list
fi

#--- KAMAILIO ---#
export PATH_KAMAILIO_CFG=/etc/kamailio/kamailio.cfg
kamailio=$(which kamailio)

# Test the config syntax
$kamailio -f $PATH_KAMAILIO_CFG -c

# Run
$kamailio -m "${SHM_MEM}" -M "${PKG_MEM}" -f $PATH_KAMAILIO_CFG -DD -E -e
