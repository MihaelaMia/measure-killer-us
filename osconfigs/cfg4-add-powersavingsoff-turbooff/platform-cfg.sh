#!/bin/bash

: ${HOMEDIR?"Need to set  HOMEDIR"}
cd $HOMEDIR/osconfigs
./powersaveoff.sh
echo "Powersave off done"
