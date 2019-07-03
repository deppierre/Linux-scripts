#/bin/bash

#git clone git@git01fe.dc1.vl306.fr.its:infradoc/dbdoc.git
#git clone git@gitlab.sys.lab.ingenico.com:axiskernel/database-meteo.git
#git clone git@gitlab.sys.lab.ingenico.com:platform/puppet/postgres_ingenico.git

gitDir="$HOME/git_repo"

if [ -d "$gitDir" ]; then

	for d in $gitDir/*/ 
	do
		cd "$d"
		git pull
	done
	#rsync vers dbabatch
	rsync --update -avz /home/pdepretz/git_repo/ pdepretz@dbabatch101fe.dc1.vl99.fr.its:/home/users/pdepretz/git_repo
else 
	echo "Il faut initialiser le dossier $gitDir"
fi


