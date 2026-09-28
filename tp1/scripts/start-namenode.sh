#!/bin/bash
set -e
mkdir -p /data/name
if [ ! -f /data/name/current/VERSION ]; then
  hdfs namenode -format -force -nonInteractive
fi
exec hdfs namenode
