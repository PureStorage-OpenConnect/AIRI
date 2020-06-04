#!/bin/bash
# run_iozone.sh script

set -e
set -x

if [[ $# -ne 5 ]]; then
  echo "Usage: $0 <clients> <io-size> <file-size> <FlashBlade-data-VIP> <filesystem>"
  exit 1
fi


MASTER=iozone-master
NETWORK=iozone-net

CLIENTS=$1
RECSIZE=$2
FILESIZE=$3
DATA_VIP=$4
FSNAME=$5

echo "Parameters"
echo "  # clients:   $CLIENTS"
echo "  record size: $RECSIZE"
echo "  file size:   $FILESIZE"
echo "  data VIP:    $DATA_VIP"
echo "  filesytem:   $FSNAME"       

docker network inspect $NETWORK > /dev/null 2>&1 || \
    docker network create --subnet=10.10.0.0/16 $NETWORK


echo "Creating container master"
docker run -itd --privileged \
    --name=$MASTER \
    --net=$NETWORK \
    --hostname=$MASTER \
    iozone /bin/bash

for I in `seq 1 $CLIENTS`; do
  CONTAINER=iozone-$I
  echo "Creating container $CONTAINER"
  docker run -itd --privileged \
    --name=iozone-$I \
    --net=$NETWORK \
    --hostname=iozone-$I \
    iozone /usr/sbin/inetd -d /etc/inetd.conf

  sleep 0.1

  echo "Mounting filesystem in $CONTAINER"
  docker exec $CONTAINER mount -t nfs -o tcp,vers=3,nolock $DATA_VIP:/$FSNAME /tmp/ir
  docker exec $CONTAINER mkdir -p /tmp/ir/iozone-$I
  docker exec $CONTAINER /bin/bash -c 'echo "iozone-master root" > /root/.rhosts'

  docker exec $MASTER /bin/bash -c "echo $CONTAINER /tmp/ir/$CONTAINER /usr/bin/iozone >> /tmp/clients"
done

REDUCTION_NONE="-+w 1"
REDUCTION_3TO1="-+w 66 -+y 100 -+C 100"

echo "Starting tests"
docker exec $MASTER iozone -I -c -e -w -C \
    $REDUCTION_3TO1 \
    -+n -+m /tmp/clients -O -T \
    -t $CLIENTS -r $RECSIZE -s $FILESIZE \
    -i 0 -i 1 -i 2

echo "Purging all existing iozone containers"
docker stop iozone-master
docker rm iozone-master
for I in `seq 1 $CLIENTS`; do
  CONTAINER=iozone-$I
  echo "Stopping container $CONTAINER"
  docker stop $CONTAINER
  docker rm $CONTAINER
done

