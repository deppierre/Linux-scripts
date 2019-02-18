#!/bin/bash

# permet de forcer l'archivage des wall avec pgbackrest
#recette sur ursobdh02

########################## VARIABLE ##############################

ARCHIVE_READY_DIRECTORY=$WALL_DIRECTORY"/archive_status"
NBDAYS=6
CURRENT_USER=$(whoami)

########################## CONSTANTE #############################
LOG_WARN="WARN:"
LOG_ERROR="ERROR:"

if [[ $CURRENT_USER =~ "postgres" ]];
then
	echo "INFO : profil OK : $CURRENT_USER"
	#prompt pour saisir instance/postmaster
	read -p "Merci de saisir le nom de l'instance a purger : " INSTANCE_NAME
	source ~/dmgpgenv -v $INSTANCE_NAME > /dev/null 
	
	if [ -f "$PGDATA/postmaster.opts" ]
	then
		WALL_DIRECTORY=$PGDATA"/pg_xlog"
		echo "INFO : PGDATA OK : $PGDATA"
		echo "INFO : PGWALL OK : $WALL_DIRECTORY"
		sleep 60

		# on liste tous les fichiers de wall avec un status ready
		for i in $(find $ARCHIVE_READY_DIRECTORY -type f -mtime $NBDAYS -name *.ready); do
			echo "$i"
			filename=$(basename "$i")
			extension="${i##*.}"
			filenameWithoutPath="${i##*/}"
			filenameOnly="${filenameWithoutPath%.*}"
			
			#echo filename "$filename"
			#echo extension "$extension"
			
			# fichier dans le repertoire des walls
			FICHIER_WALL=$WALL_DIRECTORY/$filenameOnly
			echo "wall file : " $FICHIER_WALL
			
			# on verifie l'existance du fichier de wall
			if [ -f "$FICHIER_WALL" ]
			then
				echo "found"
				LOG_PGBACKREST=$(pgbackrest --stanza=$INSTANCE_NAME archive-push $FICHIER_WALL)
				#echo $LOG_PGBACKREST
				if [[ $LOG_PGBACKREST =~ $LOG_ERROR ]];
				then
					echo "ERROR : file $FICHIER_WALL avec l'erreur : $LOG_PGBACKREST"
				elif [[ $LOG_PGBACKREST =~ $LOG_WARN ]];
				then
					echo "WARNING : de traitement pour le fichier $FICHIER_WALL avec le warning : $LOG_PGBACKREST"
				else
					# le traitement pour le fichier a été fait sans erreur, on poursuis le traitement
					echo "INFO : on traite $i"
					mv $i $ARCHIVE_READY_DIRECTORY/$filenameOnly".done"
					echo "INFO:: on traite $FICHIER_WALL"
					rm -f $FICHIER_WALL
				fi
			fi
			break
		done
	else
		echo "ERROR : instance introuvable"
	fi
else
	echo "ERROR : merci d'utiliser l'user POSTGRES"
fi