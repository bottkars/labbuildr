#!/bin/bash
/etc/systool --setoverrides /etc/ovfenv.properties 
/etc/systool --getoverrides  
/etc/systool --getprops 
ls /.volumes/bootfs/etc
/etc/systool --reconfig
rcnetwork restart
ls /.volumes/bootfs/etc  
# /etc/systool --reboot
     