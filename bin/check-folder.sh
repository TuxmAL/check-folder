#!/bin/bash

# Copyright Antonio Liccardo (C) 2012
# check-folder: a bash script checking for updated file in a folder
# Author::    TuxmAL (mailto:tuxmal@tiscali.it)
# Copyright:: Copyright (c) 2013 TuxmAL
# License::
#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
# 
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <http://www.gnu.org/licenses/>.

# application name for notification.
APP_NAME="Check folder"

# directory to check
CHECKED_DIR=/home/tuxmal/shared
# directory display name for notification
CHECKED_DIR_NAME=$( basename ${CHECKED_DIR}  )

# configuration directory, where are stored data needed for last update
CONFIG_DIR=/home/tuxmal/.$( basename ${0} .sh )
# last file found into the checked directory
LAST_FILE=last_file
# last change time for the last file found into the checked directory
LAST_FILE_CHANGE=last_change
# owner for dir and files (needed when the script is lauched as root)
CONFIG_OWNER=tuxmal

# message title
TITLE="<i>Check for updated files</i>"
# message body
BODY_NO_NEWER_FILE="No updates in <i>${CHECKED_DIR_NAME}</i> folder."

# options variable 
notify_all_users=yes	# notify to all users if ran as root!
notify_no_upd=no	# notify user if no update occurs

function newerfile() 
{
  files=(${1}/*)
  newest=${files[0]}
  for f in "${files[@]}"; do
    if [[ $f -nt $newest ]]; then
      newest=$f
    fi
  done
  echo $(basename "${newest}")
}

function help()
{
cat <<End-Of-Help
Usage: `basename $0` [-ahu]
  Check a folder for new files and notify this to the user via notifiy-send. 
  If ran as root it will notify every user logged in (useful as cron task).
   a	notify even if no new document are found
   h	this help
   u	notify only the user running the script (for root so that other users do not get bored) 
End-Of-Help
}

# option parsing 
while getopts "ahu" opzione 
  do case ${opzione} in 
    a ) notify_no_upd=yes
    ;;
    h )  help ; exit 0
    ;;
    u ) notify_all_users=no
    ;; 
   * ) help ; exit 1
   ;; 
  esac 
done
shift $(($OPTIND - 1)) 

if [ ! -d ${CONFIG_DIR} ]; then 
  mkdir -p ${CONFIG_DIR}
  chown -R ${CONFIG_OWNER}.${CONFIG_OWNER} ${CONFIG_DIR}
fi

if [ ! -f "${CONFIG_DIR}/${LAST_FILE}" ]; then 
  touch "${CONFIG_DIR}/${LAST_FILE}"
  date +"%s" > "${CONFIG_DIR}/${LAST_FILE_CHANGE}"
  chown ${CONFIG_OWNER}.${CONFIG_OWNER} "${CONFIG_DIR}/${LAST_FILE}"
  chown ${CONFIG_OWNER}.${CONFIG_OWNER} "${CONFIG_DIR}/${LAST_FILE_CHANGE}"
fi

urge=""
x=$( newerfile ${CHECKED_DIR} )
echo "${x}" | cmp -s "${CONFIG_DIR}/${LAST_FILE}" -
if [ $? != 0 ]; then
  echo "${x}" > "${CONFIG_DIR}/${LAST_FILE}"
  stat -c"%Z" "${CHECKED_DIR}/${x}" > "${CONFIG_DIR}/${LAST_FILE_CHANGE}"  
  urge=critical
else
  expr_elapsed_hrs="$( date +"%s" ) $( cat "${CONFIG_DIR}/${LAST_FILE_CHANGE}" ) - 3600 / p"
  elapsed_hrs=$( dc -e"${expr_elapsed_hrs}" )
  case ${elapsed_hrs} in 
    [0-1])
	urge=critical
	;;
    [2-4])
	urge=normal
	;;
    [5-28])
	urge=low
	;;
    *)
	urge=""
	;;
  esac

if [ ! -z "${urge}" ]; then
  notifier="notify-send -a \"${APP_NAME}\" -u ${urge} -i document-new -c transfer \"${TITLE}\" \"<b>${x}</b> now available in folder <i>${CHECKED_DIR_NAME}</i>.\""
else
  if [ ${notify_no_upd} = "yes" ]; then
    notifier="notify-send -a \"${APP_NAME}\" -u low -i document-new -c transfer -t 4500 \"${TITLE}\" \"${BODY_NO_NEWER_FILE}\""
  else
    notifier='echo -n'
  fi
fi
if [ ${notify_all_users} = "yes" -a "${EUID}" = "0" ]; then
  for i in $(users | tr " " "\n" | sort | uniq) ;  do
    su ${i} -c "DISPLAY=\":0.0\" ${notifier}"
  done
else  
  eval ${notifier}
fi
