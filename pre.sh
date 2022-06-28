#!/bin/bash

DIR=/opt/PURE
DATE=$(date +%Y%m%d_%H%M)
LOGFILE=${DIR}/log/${DATE}.pre.log
ERRFILE=${DIR}/log/${DATE}.err
RCPT="D.Isakovskiy@example.com"
LOCKB=/oracle/ER2/sapbackup/.backup.lock
{

###### Touching lockfile ######
if [ -f $LOCKB ]; then
    echo "$LOCKB already exist..."
    echo " $LOCKB exist!!! Please check if backup already running or remove $LOCKB file" | mailx -s "ER2 snap backup problem .." $RCPT 
    exit 1001
else
    echo "touching lockfile"
    touch $LOCKB
fi

###### Create snapshot #######
date
echo creating snap ...
echo "purepgroup snap --suffix A sapdata" | ssh M70-2 
if [ $? -gt 0 ]; then
    echo "purepgroup snap --suffix A sapdata failed..." | mailx -s "ER2 snap backup problem .." $RCPT
    exit 101
else
    date
    echo snap created
fi

###### Copy snapshot volumes to the clone volumes ######
date
ssh M70-2 "purevol list --pgrouplist sapdata.A --snap" 
if [ $? -gt 0 ]; then
    echo "purevol --snap problem in sapdata.A ..." | mailx -s "ER2 snap backup problem .." $RCPT
    exit 111
else
    echo copying vols ...
    cat ${DIR}/purevol.copy.cmd |ssh M70-2 
    date 
    echo end copying vols
fi

###### importing vg groups (may be already imported) #######
echo "importing ER2datavg* ..."
sudo importvg -y ER2datavg1 00cf9a17a5472368 || (echo "sudo importvg -y ER2datavg1 00cf9a17a5472368 failed ..." | mailx -s "ER2 snap backup problem .." $RCPT; exit 151)
sudo importvg -y ER2datavg2 00cf9a17a54731ad || (echo "sudo importvg -y ER2datavg2 00cf9a17a54731ad failed ..." | mailx -s "ER2 snap backup problem .." $RCPT; exit 152)
sudo importvg -y ER2datavg3 00cf9a17a54737eb || (echo "sudo importvg -y ER2datavg3 00cf9a17a54737eb failed ..." | mailx -s "ER2 snap backup problem .." $RCPT; exit 153)
sudo importvg -y ER2datavg4 00cf9a17a5473e03 || (echo "sudo importvg -y ER2datavg4 00cf9a17a5473e03 failed ..." | mailx -s "ER2 snap backup problem .." $RCPT; exit 154)
sudo importvg -y ER2datavg5 00cf9a17a547444a || (echo "sudo importvg -y ER2datavg5 00cf9a17a547444a failed ..." | mailx -s "ER2 snap backup problem .." $RCPT; exit 155)
sudo importvg -y ER2datavg6 00cf9a17a5474a81 || (echo "sudo importvg -y ER2datavg6 00cf9a17a5474a81 failed ..." | mailx -s "ER2 snap backup problem .." $RCPT; exit 156)
sudo importvg -y ER2datavg7 00cf9a17a54750b3 || (echo "sudo importvg -y ER2datavg7 00cf9a17a54750b3 failed ..." | mailx -s "ER2 snap backup problem .." $RCPT; exit 157)
sudo importvg -y ER2datavg8 00cf9a17f34df2d7 || (echo "sudo importvg -y ER2datavg8 00cf9a17f34df2d7 failed ..." | mailx -s "ER2 snap backup problem .." $RCPT; exit 158)
sudo importvg -y ER2datavg9 00cf9a17a54756e3 || (echo "sudo importvg -y ER2datavg9 00cf9a17a54756e3 failed ..." | mailx -s "ER2 snap backup problem .." $RCPT; exit 159)
sudo importvg -y ER2datavg10 00cf9a17a5475d03 || (echo "sudo importvg -y ER2datavg10 00cf9a17a5475d03 failed ..." | mailx -s "ER2 snap backup problem .." $RCPT; exit 160)
sudo importvg -y ER2datavg11 00cf9a17a5476322 || (echo "sudo importvg -y ER2datavg11 00cf9a17a5476322 failed ..." | mailx -s "ER2 snap backup problem .." $RCPT; exit 161)
sudo importvg -y ER2datavg12 00cf9a17a547693d || (echo "sudo importvg -y ER2datavg12 00cf9a17a547693d failed ..." | mailx -s "ER2 snap backup problem .." $RCPT; exit 162)
sudo importvg -y ER2datavg13 00cf9a17f34e3fe9 || (echo "sudo importvg -y ER2datavg13 00cf9a17f34e3fe9 failed ..." | mailx -s "ER2 snap backup problem .." $RCPT; exit 163)
sudo importvg -y ER2datavg14 00cf9a17a5476f4e || (echo "sudo importvg -y ER2datavg14 00cf9a17a5476f4e failed ..." | mailx -s "ER2 snap backup problem .." $RCPT; exit 164)

###### varyonvg groups #########
echo "varyonvg  ER2datavg* ..."
for i in {1..14}; do
    sudo varyonvg ER2datavg${i} 
    if [ $? -gt 0 ]; then
        echo "varyonvg ER2datavg${i} failed ..." | mailx -s "ER2 snap backup problem .." $RCPT    
        exit 121
    fi
done

######  mounting sapdata #########
echo "mounting sapdata* ..."
for i in {1..14}; do
    sudo mount -o cio,noatime /dev/ER2sapdata${i}lv /oracle/ER2/sapdata${i} 
    if [ $? -gt 0 ]; then
        echo "mount -o cio,noatime /dev/ER2sapdata${i}lv /oracle/ER2/sapdata${i} failed ..." | mailx -s "ER2 snap backup problem .." $RCPT
        exit 131
    fi
done

###### set access for sap group ######
echo "chmoding /oracle/ER2/sapdata* ..."
sudo chmod -R g+w /oracle/ER2/sapdata*
if [ $? -gt 0 ]; then
    echo "chmod -R g+w /oracle/ER2/sapdata* failed ..." | mailx -s "ER2 snap backup problem .." $RCPT
    exit 141
fi

###### removing lockfile #######
rm $LOCKB > /dev/null 2>/dev/null
echo rm $LOCKF

} >> ${LOGFILE} 2>> ${LOGFILE}

#cat ${LOGFILE} | mailx -s "ER2 snap backup successfully - pre.sh log" $RCPT
exit 0
