#/bin/bash

set -x

PORT=$1

if [ $# -ne 1 ];
    then echo "Need to specify a port!"
    exit
fi

echo "Connecting to sandbox Compute Node, Port to use is $PORT"

# you'll likely need to update the IP address here
ssh -o TCPKeepAlive=yes -N -n sandbox -L $PORT:192.168.220.66:$PORT
