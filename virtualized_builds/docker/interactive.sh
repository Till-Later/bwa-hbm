#! /bin/bash -e

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

docker-compose -f docker-compose.linux.yml run xilinx-vivado /bin/bash
