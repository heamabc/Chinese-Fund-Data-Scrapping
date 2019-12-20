#!/bin/bash
# It is in UTC, 15 in UTC is 23 in Hong Kong as HKT is UTC + 8
# To stop the program, press ctrl + c in the command
while :
    do
        TIME=$(date '+%H');
        if [ $TIME == '15' ];
        then
            echo Time matched, current hour is $TIME, run program..., ;
            python main.py;
            echo Sleep 1 hour;
            sleep 3600;
            
        else
            echo Time not matched, sleep 1 hour, current hour is $TIME;
            sleep 3600;
        fi
    done
