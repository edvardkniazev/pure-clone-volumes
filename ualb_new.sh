#!/bin/sh
ORAARCH=/dev/ER2archlv
VAULTLOCKFILE=/oracle/ER2/sapbackup/vault.lock
LOCKFILE=/usr/sap/scripts/ualb/ualb.lock
LOGFILE=/usr/sap/scripts/ualb/ualb`date +%d%m%y`.log
BRAFILE=/usr/sap/scripts/ualb/ualb`date +%d%m%y`.bal
PROFILE=initER2.sap
#PROFILE=initER2_rman_log.sap
LOCKB=/oracle/ER2/sapbackup/.backup.lock
MINPERC=1
N=1 # added

###### added by disakovskiy 15 Nov 2019 
BACKFILE=$(find /oracle/ER2/sapbackup -name *.aff -mmin  -30 ) ## test if backup just started
if [ ${#BACKFILE} -gt 0 ]; then
    TESTSTB=$(grep "Start and mount of database instance ER2/STANDBY successful" $BACKFILE| wc -l)
    if [ $TESTSTB -ne 1 ]; then
         exit
    fi
fi 

if [ -f $LOCKB ]; then exit;fi # creating snapshot for backup
###### end 15 Nov 2019 #########

find /usr/sap/scripts/ualb/ualb*.log -mtime +31 -exec rm {} \;
find /usr/sap/scripts/ualb/ualb*.bal -mtime +31 -exec rm {} \;

T=`date +%H:%M:%S`
ACTPERC=`df -g | grep $ORAARCH | awk '{print $4}' | sed 's/%//'`

if [ -f $VAULTLOCKFILE ]; then
    exit 2
fi

if [ ! -s $LOCKFILE ]; then
    echo $$ > $LOCKFILE;
    TESTN=$(find /oracle/ER2/saparch/ -name '*.svd' -mmin -$N|wc -l) #added

    if [ "$ACTPERC" -gt "$MINPERC" -o  $TESTN -eq 0 ]; then
        echo "$T - $ACTPERC%    : BR*Archive started..." >> $LOGFILE;
        brarchive -u // -c force -p $PROFILE -sd >> $BRAFILE;
        RC=$?;
        T=`date +%H:%M:%S`
        ACTPERC=`df -g | grep $ORAARCH | awk '{print $4}' | sed 's/%//'`
        echo "$T - $ACTPERC%    : BR*Archive finished (RC=$RC)" >> $LOGFILE;
    else
        echo "$T - $ACTPERC%    : Archive log directory check completed." >> $LOGFILE
    fi    
        : > $LOCKFILE
    exit 0

else
    TESTN=$(ps -ef | grep brarchive | grep -v grep | grep -v $$ | wc -l)
    if [ $TESTN -eq 0 ]; then
        echo "$T - $ACTPERC% : Archive log directory check completed - ERROR: LOCKFILE is present, but BRARCHIVE not found" >> $LOGFILE

        echo "$T - $ACTPERC% : Archive log directory check completed - ERROR: LOCKFILE is present, but BRARCHIVE not found" | mailx -s "UALB: ArchiveLog Backup on `date +%d.%m.%Y_%H:%M` (Error)"  sap_bc_alerts@x5.ru

    else
        echo "$T - $ACTPERC% : Archive log directory check completed - OK: BRARCHIVE is working..." >> $LOGFILE
    fi
    exit 2
fi  
