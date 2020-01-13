#/bin/bash
read -p "Merci de saisir le nom de l'instance (stanza) a purger : " STANZA
PGBACKREST_CONF="/etc/pgbackrest.conf"
PGBACKREST_CONF_SAVE="/home/postgres/backup/pgbackrest/conf"
PGBACKREST_BACKUP="/home/postgres/backup/pgbackrest/backup/$STANZA"
PGBACKREST_ARCHIVE="/home/postgres/backup/pgbackrest/archive/$STANZA"

if [[ -f "$PGBACKREST_CONF" ]];
then
	grep $STANZA $PGBACKREST_CONF > /dev/null
	if [[ ${?} == 0 ]]; 
	then
		cp $PGBACKREST_CONF $PGBACKREST_CONF_SAVE/pgbackrest.conf.$(date +%Y%m%d)
		cat $PGBACKREST_CONF | sed -e '/'$STANZA'/,/^\s*$/d' > $PGBACKREST_CONF_SAVE/pgbackrest.conf.new
		echo "info : mise à jour de la conf OK"
		if [[ -d $PGBACKREST_BACKUP ]]
		then
			rm -rf $PGBACKREST_BACKUP/*
			rmdir $PGBACKREST_BACKUP
			echo "info : suppression dossier BACKUP OK"
			echo "dossier : $PGBACKREST_BACKUP"
		fi
		if [[ -d $PGBACKREST_ARCHIVE ]]
		then
			rm -rf $PGBACKREST_ARCHIVE/*
			rmdir $PGBACKREST_ARCHIVE
			echo "info : suppression dossier ARCHIVE OK"
			echo "dossier : $PGBACKREST_ARCHIVE"
		fi
		echo "purge terminee !"
        echo "nouveau fichier : $PGBACKREST_CONF_SAVE/pgbackrest.conf.new"
	else
		echo "erreur : stanza introuvable"
		exit
	fi
else
	echo "erreur : Fichier pgbackrest introuvable"
fi
