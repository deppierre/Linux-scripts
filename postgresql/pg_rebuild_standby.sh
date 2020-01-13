#/bin/bash
read -p "Merci de saisir le nom de la base a purger : " PGBDD
source /home/postgres/dmgpgenv $PGBDD
CURRENT_USER=$(whoami)
BACKUP_CONF="/home/postgres/backup/conf"

if [[ $CURRENT_USER =~ "postgres" ]];
then
	if [[ $PGDATA != " " ]];
	then
		if [[ -f "$PGDATA/recovery.conf" ]] || [[ -z "$(ls -A $PGDATA)" ]];
		then
			INSTANCE_STATUS=$(pg_ctl status -D $PGDATA)
			if [[ ! $INSTANCE_STATUS =~ "pg_ctl: no server running" ]];
			then
				echo "INFO: Arret de la base $PGBDD"
				pg_ctl stop -m immediate -D $PGDATA
			else
				echo "INFO: Base $PGBDD deja arretee"
			fi
			
			#sauvegarde de la conf
			echo "INFO: Sauvegarde de la conf $PGDATA"
			if [[ ! -d "$BACKUP_CONF" ]];
			then
				mkdir $BACKUP_CONF
			fi
			cp $PGDATA/*.conf $BACKUP_CONF -f
			TARGET_HOST=$(awk '/password/{print $3}' $BACKUP_CONF/recovery.conf | cut -d= -f2)
			TARGET_PORT=$(awk '/password/{print $4}' $BACKUP_CONF/recovery.conf | cut -d= -f2)
			TARGET_USER=$(awk '/password/{print $5}' $BACKUP_CONF/recovery.conf | cut -d= -f2)
			TARGET_PWD=$(awk '/password/{print $6}' $BACKUP_CONF/recovery.conf | cut -d= -f2)
			
			#supression des données de PGDATA
			echo "INFO: Suppression des données dans le répertoire  $PGDATA"
			   
			find -L $PGDATA -type f -exec rm {} \; 2>/dev/null
			find -L $PGDATA -depth -exec rmdir {} \; 2>/dev/null
			find  $PGDATA -exec rm {} \; 2>/dev/null
			find  $PGDATA -depth -exec rmdir {} \; 2>/dev/null
			
			#restauration
			echo "INFO: reinitialisation de l instance, mdp a saisir : $TARGET_PWD"
			pg_basebackup --progress -D $PGDATA --xlog -v --host=$TARGET_HOST --port=$TARGET_PORT -U $TARGET_USER -P
			mv $PGDATA/pg_xlog/* $PGDATA/../pg_xlog/
			find -L $PGDATA/pg_xlog -type f -exec rm {} \; 2>/dev/null
			find -L $PGDATA/pg_xlog -depth -exec rmdir {} \; 2>/dev/null
			ln -fsn $PGDATA/../pg_xlog $PGDATA/pg_xlog
			
			#restauration de la conf
			cp $BACKUP_CONF/*.conf $PGDATA -f
			chmod 0700 $PGDATA
			
			#demarrage
			echo "INFO: Demarrage de l instance"
			pg_ctl start -w -t 5 -l /dev/null -D $PGDATA
			
			#test
			echo "..."
			sleep 60
			if [[ ! $INSTANCE_STATUS =~ "pg_ctl: no server running" ]];
			then
				TEST_REPLIOK=$(psql -xc "SELECT pg_is_in_recovery();" | grep pg_is_in_recovery | cut -d ' ' -f3)
				if [[ $TEST_REPLIOK =~ "t" ]];
				then
					echo "INFO: Replication OK"
				else
					echo "ERROR: Replication KO"
				fi
			else
				echo "ERROR: BDD $PGBDD KO, verifier les logs"
			fi
		else
			echo "ERROR: instance non-standby"
		fi
	else
		echo "ERROR: instance inexistante ou installation non standard (master unifie) ?"
	fi
else
	echo "ERROR: merci d'utiliser user POSTGRES"
fi	
