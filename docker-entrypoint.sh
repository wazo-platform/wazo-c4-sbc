#!/bin/sh
date

mkdir -p /etc/kamailio/
echo '#!define LISTEN '$LISTEN > /etc/kamailio/kamailio-local.cfg

#--- KAMAILIO ---#
export PATH_KAMAILIO_CFG=/etc/kamailio/kamailio.cfg
kamailio=$(which kamailio)

# Test the config syntax
$kamailio -f $PATH_KAMAILIO_CFG -c

# Run
$kamailio -m "${SHM_MEM}" -M "${PKG_MEM}" -f $PATH_KAMAILIO_CFG -DD -E -e
