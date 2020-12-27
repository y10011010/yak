PROJECT ?= Desktop

RESTIC_REPOSITORY = rest:http://fanger.local:8000

PROJECT_SNAPSHOT_ID = $(shell cat ${HOME}/${PROJECT}/.latest)

HOME_SNAPSHOT_ID = $(shell cat ${HOME}/.latest)

PASSWORDS_FOR_PROJECT = ${HOME}/.password-store/${PROJECT}

GIT_DIR = ${HOME}/${PROJECT}/.git

TMUX_LOGS_FOR_PROJECT = ${HOME}/tmux-${PROJECT}-*.log

HOME_DATA = ${HOME}/.timewarrior ${HOME}/.ssh ${HOME}/.gnupg
PROJECT_DATA = ${TMUX_LOGS_FOR_PROJECT} ${PASSWORDS_FOR_PROJECT} ${GIT_DIR}


default: ${PROJECT}

.PHONY: ${HOME}/.latest ${HOME}/${PROJECT}/.latest ${PROJECT} stop push fetch


${PROJECT}: restore
	tmuxinator start $@


clean: stop push ${HOME}/.latest ${HOME}/${PROJECT}/.latest
	rm -rf ${HOME_DATA}
	rm -rf ${PROJECT_DATA}
	rm -rf ${HOME}/${PROJECT}/*
	echo "\nCleaned workspace"


restore: fetch start



start:
	timew $@ ${HOME} ${PROJECT}


stop:
	timew stop


fetch: ${HOME}/${PROJECT}
	# git $@


push:
	# git push


# TODO set ENV for restic
${HOME}:
	restic restore -p ${HOME}/.restic -r ${RESTIC_REPOSITORY} ${HOME_SNAPSHOT_ID} --target /


${HOME}/${PROJECT}: ${HOME}
	restic restore -p ${HOME}/.restic -r ${RESTIC_REPOSITORY} ${PROJECT_SNAPSHOT_ID} --target /

# ${HOME}.tar.gz: ${HOME_DATA}
# 	tar caf $@ $?
#
# ${HOME}/${PROJECT}.tar.gz: ${PROJECT_DATA}
# 	tar caf $@ $?
#

${HOME}/.latest: ${HOME_DATA}
	@restic --json \
		-p ${HOME}/.restic \
		-r ${RESTIC_REPOSITORY} \
		backup $? \
		| jq -rc .snapshot_id \
		| tail -n 1 \
		> $@


${HOME}/${PROJECT}/.latest: ${PROJECT_DATA}
	@restic --json \
		-p ${HOME}/.restic \
		-r ${RESTIC_REPOSITORY} \
		backup $? \
		| jq -rc .snapshot_id \
		| tail -n 1 \
		> $@

TMUXINATOR_HEADER = dev/inventory/templates/tmuxinator/header.txt
TMUXINATOR_WINDOWS ?= dev/inventory/templates/tmuxinator/windows.txt

.config/tmuxinator/${PROJECT}.yml:
	cat ${TMUXINATOR_HEADER} > $@
	cat ${TMUXINATOR_WINDOWS} >> $@
	cat $@


