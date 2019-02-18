#!/bin/bash
#COMMANDE A AJOUTER DANS CRON * * * * * /home/mongodb/DockerStats.sh
ACTIVATION=1
CONTAINER_TO_WATCH="PMT"
OUT_DIR="/home/mongodb/DockerStats"
OUTPUT="$OUT_DIR/$(date +%Y-%m-%d)_DockerStat.json"

if [ ! -d $OUT_DIR ]
then
	mkdir $OUT_DIR
fi

if [[ $ACTIVATION == 1 ]];
then
	for DOCKID in `docker ps --filter "NAME=$CONTAINER_TO_WATCH" --format "{{.ID}}"`;do
		docker stats $DOCKID --no-stream --format \
		"{\"date\":\"$(date +%d/%m/%y' '%H:%M)\",\"container\":\"{{ .Name }}\",\"memory\":{\"raw\":\"{{ .MemUsage }}\",\"percent\":\"{{ .MemPerc }}\"},\"cpu\":\"{{ .CPUPerc }}\"}" >> $OUTPUT
	done
else
	echo "Warning:Les traces sont desactivees"
fi