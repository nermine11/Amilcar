#!/bin/bash

# Infinite loop: check GPS fix every 1 second, update RTC if GPS is valid, else 
#set system time to RTC time
while true; do
    if gpspipe -w -n 5 | grep -q '"mode":3'; then
        hwclock -w
        echo " GPS fix: using GPS time, updating RTC" >> /tmp/gps-rtc.log

    # no GPS fix use RTC
    else
       hwclock -s
       echo "$  no GPS fix: using RTC" >> /tmp/gps-rtc.log
    fi
    sleep 1
done