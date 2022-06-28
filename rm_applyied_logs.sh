#!/bin/bash

DIR=$(dirname $0)
LOGFILE=${DIR}/log/rm_applyied_logs.log
LOGFILE2=${DIR}/log/rm_applyied_logs2.log
RCPT="sap_bs_alerts@example.com,DIS.SAPBasis@example.com"
: > $LOGFILE

{
#date
MS=$(sqlplus -silent / as sysdba<<EOF
SET HEAD OFF
select max(sequence#) from v\$archived_log where applied='YES';
EXIT;
EOF)

if [ $? -gt 0 ]; then
    echo "select max(sequence#) from v$archived_log where applied='YES' failed"| mailx -s "ER2STB : Some problem with rm_applyied_logs.sh... " $RCPT
    exit 110
fi

MAXS=$(echo $MS | tr -d '\n')
if [ ${#MAXS} -eq 0 -o ! $MAXS -eq $MAXS ] 2>/dev/null; then 
    echo "max(sequence#) is not a integer" | mailx -s "ER2STB : Some problem with rm_applyied_logs.sh... " $RCPT
    exit 120
fi

for f in $(find /oracle/ER2/oraarch -name ER2arch1_*_938991754.dbf); do
    SEQ=$(echo $f|awk -F '_' '{print $2}')
    if [ $SEQ -lt $MAXS ]; then
        rm $f # rm echo for executing
        if [ $? -gt 0 ]; then
            echo "rm $f failed" | mailx -s "ER2STB : Some problem with rm_applyied_logs.sh... " $RCPT
            exit 130
        fi
    fi
done
} > $LOGFILE 2>$LOGFILE

if [ -s $LOGFILE ]; then
    cat $LOGFILE | mailx -s "ER2STB : Some problem with rm_applyied_logs.sh... " $RCPT
    cat $LOGFILE >> $LOGFILE2
fi
