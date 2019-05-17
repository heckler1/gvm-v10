#!/bin/sh

# This just updates the NVTs/CERT/SCAP data for GVM
/usr/sbin/greenbone-nvt-sync 
/usr/sbin/greenbone-certdata-sync 
/usr/sbin/greenbone-scapdata-sync 
