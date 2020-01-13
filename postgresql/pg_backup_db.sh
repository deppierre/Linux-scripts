#!/bin/bash
#
# Script de backup d'une base postgresql
#
# Parametres :
# $1 = nom de l'instance a sauvegarder ( XXXTyy )

function Trace {
   echo `date +"%d/%m/%Y %H:%M"`" - $1"
}

function Retour {
  Trace "$1"
  sleep 1 # pour laisser le temp a la redirection vers tee d'afficher
  exit $2
}

NOMINST=$1
PGDATA=/home/postgres/${NOMINST}/instance
if [ ! -d ${PGDATA} ] ; then Retour "Repertoire PGDATA introuvable" 1 ; fi
PGPORT=`grep -i "port =" ${PGDATA}/postgresql.conf | awk -F= '{ print $2 }' | awk '{ print $1 }'`
if [ -z ${PGPORT} ] ; then Retour "PGPORT introuvable" 1 ; fi
DATETIME=`date +%"d%m%Y_%H%M"`
BACKUPDIR=/home/postgres/backup/${NOMINST}   # FS contenant les jeux de sauvegarde
BACKUPLOGS=/home/postgres/backup/${NOMINST}/backup_${NOMINST}_${DATETIME}.log
touch ${BACKUPLOGS}
if [ ! -w ${BACKUPLOGS} ] ; then Retour "Erreur sur fichier ${BACKUPLOGS}" 1 ; fi
TAR='tar cvzfC'
unset PGDATABASE
PGTAB=/etc/pgtab
PGVERS=`awk -F : '$2=="'${NOMINST}'" {print $3;exit}' ${PGTAB}`
if [ -z ${PGVERS} ] ; then Retour "PGVERS introuvable" 1 ; fi
PATH=/usr/lib/postgresql/${PGVERS}/bin:`echo ${PATH}|sed -e 's=/usr/lib/postgresql/[\.0-9]*/bin==g' -e  's=::=:=g' -e  's=^:=='  -e  's=:$==' `

. ~/dmgpgenv ${NOMINST}

# tout ce qui sort sur la sortie standard part aussi vers le tee
exec > >(tee -a ${BACKUPLOGS} )

IS_IN_RECOVERY=`psql -d postgres -p ${PGPORT} -U postgres -w -c "select pg_is_in_recovery()::int;" -t|sed '/^$/d'`

if [[ "$IS_IN_RECOVERY" -eq 1 ]] ; then
  Trace "base de donnees en mode secours, elle n'est pas sauvegardee"
  exit 0
fi

psql -p ${PGPORT} -c "select pg_start_backup('Backup du "${DATETIME}"')"
RC_BEGIN_BACKUP=$?
if [ ${RC_BEGIN_BACKUP} -eq 0 ];
then
  ####
  Trace "${TAR} ${BACKUPDIR}/backup_${NOMINST}_${DATETIME}.tar.gz /home/postgres/${NOMINST} ."
  ${TAR} ${BACKUPDIR}/backup_${NOMINST}_${DATETIME}.tar.gz /home/postgres/${NOMINST} . 2>&1
  RC_TAR=$?
  warn1=`grep 'file changed as we read it' $BACKUPLOGS |  wc -l`
  if [ ${RC_TAR} -eq 0 ];
  then
    Trace "OK"
  else
   if [ ${RC_TAR} -eq 1 -a $warn1 -gt 0 ];
   then
      Trace "OK avec warning: file changed as we read it, on force rc=0 au lieu de 1"
      RC_TAR=0
   else
      Trace "=======+++++++======= ECHEC sur le tar RC=${RC_TAR}"
      Trace "On tente quand meme le pg_stop_backup"
   fi
  fi
  ####
  Trace "Fin de backup ${PGDATA} avec pg_stop_backup"
  psql -p ${PGPORT} -c "select pg_stop_backup()"
  RC_STOP_BACKUP=$?
  if [[ ${RC_STOP_BACKUP} -eq 0 && ${RC_TAR} -eq 0 ]];
  then
    # on ne fait le pg_archivecleanup que si tout le reste est OK
    Trace "pg_archivecleanup /home/postgres/${NOMINST}/archives"
    LAST_ARCHIVE=`ls -tr /home/postgres/${NOMINST}/archives/*.backup | tail -1`
    NUM_LAST_ARCHIVE=`basename ${LAST_ARCHIVE} .00000020.backup`
    pg_archivecleanup /home/postgres/${NOMINST}/archives ${NUM_LAST_ARCHIVE}
    RC_ARCHIVECLEANUP=$?
    Trace "Fin de pg_archivecleanup"
    if [ ${RC_ARCHIVECLEANUP} -ne 0 ];
    then
      Trace "=======+++++++======= ECHEC sur le pg_archivecleanup RC=${RC_ARCHIVECLEANUP}"
    fi
  else
    Trace "=======+++++++======= ECHEC sur le pg_stop_backup() RC=${RC_STOP_BACKUP}"
    Trace "VERIFIER l'etat de la base"
  fi
else
  Retour "=======+++++++======= ECHEC sur pg_start_backup('Backup du ${DATETIME}') RC=${RC_BEGIN_BACKUP}"  ${RC_BEGIN_BACKUP}
fi

RC_GLOBAL=$(( ${RC_BEGIN_BACKUP:-0} + ${RC_TAR:-0} + ${RC_STOP_BACKUP:-0} + ${RC_ARCHIVECLEANUP:-0} ))
if [ ${RC_GLOBAL} -ne 0 ]
then
  Retour "=======+++++++======= ECHEC de la sauvegarde" ${RC_GLOBAL}
else
  Retour "Sauvegarde correcte" 0
fi
