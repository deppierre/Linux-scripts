#!/bin/bash
###########################################################################################
# Script pour purger les dumps MongoDB et Postgres dans /export/netteam/teamxisb/TRANSFERT/
########################## VARIABLE #######################################################
LOGFILE="/root/clean_teamxisb_logging/$(date +%Y%m%d).log"
DIRTOCLEAN="/export/netteam/teamxisb/TRANSFERT/EXPORT"
NBDAYS=7

#PURGE LOGFILE
if [ -f $LOGFILE ]; then
	rm -f $LOGFILE
fi

echo "-------------------------------------" | tee -a ${LOGFILE}
echo "Execution du script CLEAN_TEAMXISB.sh" | tee -a ${LOGFILE}
echo "Le $(date +%d/%m/%Y) a $(date +%H:%M:%S)" | tee -a ${LOGFILE}

#PURGE DES DUMPS
echo "------------------------------" | tee -a ${LOGFILE}
echo "Liste des fichiers supprimes :" | tee -a ${LOGFILE}
echo "------------------------------" | tee -a ${LOGFILE}

for i in `find $DIRTOCLEAN \( -name "*.POSTGRES.*" -o -name '*dmp*' -o -name '*dump*' -o -name '*.json*' -o -name '*export*' -o -name '*import*' ! -name '*KEEPFILE*' \) -mtime +$NBDAYS -type f`; do
	echo `du -BM $i` | tee -a ${LOGFILE}
	rm -f $i
	if [[ $? -ne 0 ]]; then
		echo "=> Suppression KO"
	fi
done

#PURGE DES DOSSIERS VIDES
echo "------------------------------------" | tee -a ${LOGFILE}
echo "Liste des dossiers vides supprimes :" | tee -a ${LOGFILE}
echo "------------------------------------" | tee -a ${LOGFILE}
for i in `find $DIRTOCLEAN -type d -empty`; do
	TOTALDIR=$(( $TOTALDIR + 1 ))
	echo "$i" | tee -a ${LOGFILE}
	rmdir $i
done

#GENERATION DU RESUME
TOTALFILE=`awk '{s=s+$1} END {print s}' $LOGFILE`
echo "----------------------------------------" | tee -a ${LOGFILE}
echo "Resume : " | tee -a ${LOGFILE}
echo "----------------------------------------" | tee -a ${LOGFILE}
echo "Espace total recupere : $TOTALFILE MB" | tee -a ${LOGFILE}
echo "Total des dossiers supprimes : $TOTALDIR" | tee -a ${LOGFILE}
echo "----------------------------------------" | tee -a ${LOGFILE}

###########################################################################################