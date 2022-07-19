#!/bin/sh
OKH_USER=$(/usr/bin/id -nu 1001)
/usr/sbin/usermod -G 10 $OKH_USER
