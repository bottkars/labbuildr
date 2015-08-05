#!/bin/bash
/usr/bin/ssh-keygen -t dsa -N '' -f /home/hadoop/.ssh/id_dsa
cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys;chmod 0600 ~/.ssh/authorized_keys   
/usr/bin/expect -c 'set timeout -1;spawn "/usr/bin/ssh" "hadoop@localhost";expect "*yes*no*" { send "yes\r" };interact'

