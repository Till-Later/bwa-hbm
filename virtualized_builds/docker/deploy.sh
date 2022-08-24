#! /bin/bash -e

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

docker pull docktill/xilinx-vivado:2019.2-full
docker-compose -f docker-compose.linux.yml build --no-cache
docker-compose -f docker-compose.linux.yml up -d