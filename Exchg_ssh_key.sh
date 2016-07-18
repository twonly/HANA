#!/bin/bash

### From: http://www.emc.com/collateral/white-papers/h14167-vmax-sap-tdi-lenovo-wp.pdf

# Prerequisites : all hostname of GPFS/HANA nodes are maintained in /etc/hosts file
# Exchange ssh key to each host in /etc/hosts to make keyless logon possible
# Manual input of password is still required... 

for host in `cat /etc/hosts | grep GPFSnode | awk '{print $3}'`;
do
  ping -c 1 -s 1 $host
  if [ $? -eq 0 ]; then
    ssh-copy-id -i ~/.ssh/id_rsa.pub root@$host
  fi
done
for host in `cat /etc/hosts | grep HANAnode | awk '{print $3}'`;
do
  ping -c 1 -s 1 $host
  if [ $? -eq 0 ]; then
    ssh-copy-id -i ~/.ssh/id_rsa.pub root@$host
  fi
done
