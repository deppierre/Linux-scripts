#!/bin/bash

FILE_INPUT="/root/server_list.txt"
FILE_CONTENT=`cat $FILE_INPUT`

for line in $FILE_CONTENT ; do
	SERVER_NAME=$(echo $line | cut -d';' -f1)
	SERVER_IP=$(echo $line | cut -d';' -f2)
	echo "Creation du compte sur le serveur : $SERVER_NAME ..."
	ssh -o "StrictHostKeyChecking no" root@$SERVER_IP '
	adduser adminuser
	usermod -aG wheel adminuser
	echo "adminuser:MdPTest!" | chpasswd
	mkdir /home/adminuser/.ssh
	chmod 700 /home/adminuser/.ssh
	'
	if [ $? -eq 0 ]; then
		echo "Creation du compte .... OK"
		cat id_rsa.pub | ssh root@$SERVER_IP 'cat >> /home/adminuser/.ssh/authorized_keys
		chown adminuser /home/adminuser -R
		chgrp adminuser /home/adminuser -R
		'
		if [ $? -eq 0 ]; then
			echo "Creation de la clée SSH .... OK"
		else
			echo "Creation de la clée SSH .... KO sur : $SERVER_NAME"
		fi
	else
		echo "Creation du compte .... KO sur : $SERVER_NAME"
	fi
done