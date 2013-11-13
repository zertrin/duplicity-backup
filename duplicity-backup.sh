#!/usr/bin/env bash
#
# Copyright (c) 2008-2010 Damon Timm.
# Copyright (c) 2010 Mario Santagiuliana.
# Copyright (c) 2012 Marc Gallet.
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program.  If not, see <http://www.gnu.org/licenses/>.
#
# MORE ABOUT THIS SCRIPT AVAILABLE IN THE README AND AT:
#
# http://zertrin.org/projects/duplicity-backup/ (for this version)
# http://damontimm.com/code/dt-s3-backup (for the original programi by Damon Timm)
#
# Latest code available at:
# http://github.com/zertrin/duplicity-backup
#
# ---------------------------------------------------------------------------- #

# Default config file (don't forget to copy duplicity-backup.conf.example to
# match that path)
# NOTE: It can be useful not to edit this script at all to ease future updates
#       so the config file can be specified directly on the command line too
#       with the -c option.
CONFIG="duplicity-backup.conf"

##############################################################
# Script Happens Below This Line - Shouldn't Require Editing #
##############################################################

usage(){
echo "USAGE:
    `basename $0` [options]

  Options:
    -c, --config CONFIG_FILE   specify the config file to use

    -b, --backup               runs an incremental backup
    -f, --full                 forces a full backup
    -v, --verify               verifies the backup
    -l, --list-current-files   lists the files currently backed up in the archive
    -s, --collection-status    show all the backup sets in the archive

        --restore [PATH]       restores the entire backup to [path]
        --restore-file [FILE_TO_RESTORE] [DESTINATION]
                               restore a specific file
        --restore-dir [DIR_TO_RESTORE] [DESTINATION]
                               restore a specific directory

    -t, --time TIME            specify the time from which to restore or list files
                               (see duplicity man page for the format)

    --backup-script            automatically backup the script and secret key(s) to
                               the current working directory

    -n, --dry-run              perform a trial run with no changes made
    -d, --debug                echo duplicity commands to logfile

  CURRENT SCRIPT VARIABLES:
  ========================
    DEST (backup destination)       = ${DEST}
    INCLIST (directories included)  = ${INCLIST[@]:0}
    EXCLIST (directories excluded)  = ${EXCLIST[@]:0}
    ROOT (root directory of backup) = ${ROOT}
    LOGFILE (log file path)         = ${LOGFILE}
"
}

# Some expensive argument parsing that allows the script to
# be insensitive to the order of appearance of the options
# and to handle correctly option parameters that are optional
while getopts ":c:t:bfvlsnd-:" opt; do
  case $opt in
    # parse long options (a bit tricky because builtin getopts does not
    # manage long options and I don't want to impose GNU getopt dependancy)
    -)
      case "$OPTARG" in
        # --restore [restore dest]
        restore)
          COMMAND=$OPTARG
          # We try to find the optional value [restore dest]
          if [ ! -z "${!OPTIND:0:1}" -a ! "${!OPTIND:0:1}" = "-" ]; then
            RESTORE_DEST=${!OPTIND}
            OPTIND=$(( $OPTIND + 1 )) # we found it, move forward in arg parsing
          fi
        ;;
        # --restore-file [file to restore] [restore dest]
        # --restore-dir [path to restore] [restore dest]
        restore-file|restore-dir)
          COMMAND=$OPTARG
          # We try to find the first optional value [file to restore]
          if [ ! -z "${!OPTIND:0:1}" -a ! "${!OPTIND:0:1}" = "-" ]; then
            FILE_TO_RESTORE=${!OPTIND}
            OPTIND=$(( $OPTIND + 1 )) # we found it, move forward in arg parsing
          else
            continue # no value for the restore-file option, skip the rest
          fi
          # We try to find the second optional value [restore dest]
          if [ ! -z "${!OPTIND:0:1}" -a ! "${!OPTIND:0:1}" = "-" ]; then
            RESTORE_DEST=${!OPTIND}
            OPTIND=$(( $OPTIND + 1 )) # we found it, move forward in arg parsing
          fi
        ;;
        config) # set the config file from the command line
          # We try to find the config file
          if [ ! -z "${!OPTIND:0:1}" -a ! "${!OPTIND:0:1}" = "-" ]; then
            CONFIG=${!OPTIND}
            OPTIND=$(( $OPTIND + 1 )) # we found it, move forward in arg parsing
          fi
        ;;
        time) # set the restore time from the command line
          # We try to find the restore time
          if [ ! -z "${!OPTIND:0:1}" -a ! "${!OPTIND:0:1}" = "-" ]; then
            TIME=${!OPTIND}
            OPTIND=$(( $OPTIND + 1 )) # we found it, move forward in arg parsing
          fi
        ;;
        dry-run)
          DRY_RUN="--dry-run "
        ;;
        debug)
          ECHO=$(which echo)
        ;;
        *)
          COMMAND=$OPTARG
        ;;
        esac
    ;;
    # here are parsed the short options
    c) CONFIG=$OPTARG;; # set the config file from the command line
    t) TIME=$OPTARG;; # set the restore time from the command line
    b) COMMAND="backup";;
    f) COMMAND="full";;
    v) COMMAND="verify";;
    l) COMMAND="list-current-files";;
    s) COMMAND="collection-status";;
    n) DRY_RUN="--dry-run ";; # dry run
    d) ECHO=$(which echo);; # debug
    :)
      echo "Option -$OPTARG requires an argument." >&2
      COMMAND=""
    ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      COMMAND=""
    ;;
  esac
done

# Read config file if specified
if [ ! -z "$CONFIG" -a -f "$CONFIG" ];
then
  . $CONFIG
else
  echo "ERROR: can't find config file! (${CONFIG})" >&2
  usage
  exit 1
fi
STATIC_OPTIONS="$DRY_RUN$STATIC_OPTIONS"

SIGN_PASSPHRASE=$PASSPHRASE
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export PASSPHRASE
export SIGN_PASSPHRASE
if [[ -n "$FTP_PASSWORD" ]]; then
  export FTP_PASSWORD
fi

LOGFILE="${LOGDIR}${LOG_FILE}"
DUPLICITY="$(which duplicity)"

# File to use as a lock. The lock is used to insure that only one instance of
# the script is running at a time.
LOCKFILE=${LOGDIR}backup.lock

if [ "$ENCRYPTION" = "yes" ]; then
  if [ ! -z "$GPG_ENC_KEY" ] && [ ! -z "$GPG_SIGN_KEY" ]; then
    ENCRYPT="--encrypt-key=${GPG_ENC_KEY} --sign-key=${GPG_SIGN_KEY}"
  elif [ ! -z "$PASSPHRASE" ]; then
    ENCRYPT=""
  fi
elif [ "$ENCRYPTION" = "no" ]; then
  ENCRYPT="--no-encryption"
fi

NO_S3CMD="WARNING: s3cmd is not installed, remote file \
size information unavailable."
NO_S3CMD_CFG="WARNING: s3cmd is not configured, run 's3cmd --configure' \
in order to retrieve remote file size information. Remote file \
size information unavailable."
README_TXT="In case you've long forgotten, this is a backup script that you used to backup some files (most likely remotely at Amazon S3). In order to restore these files, you first need to import your GPG private(s) key(s) (if you haven't already). The key(s) is/are in this directory and the following command(s) should do the trick:\n\nIf you were using the same key for encryption and signature:\n  gpg --allow-secret-key-import --import duplicity-backup-encryption-and-sign-secret.key.txt\nOr if you were using two separate keys for encryption and signature:\n  gpg --allow-secret-key-import --import duplicity-backup-encryption-secret.key.txt\n  gpg --allow-secret-key-import --import duplicity-backup-sign-secret.key.txt\n\nAfter your key(s) has/have been succesfully imported, you should be able to restore your files.\n\nGood luck!"

if [ ! -x "$DUPLICITY" ]; then
  echo "ERROR: duplicity not installed, that's gotta happen first!" >&2
  exit 1
fi

if  [ "`echo ${DEST} | cut -c 1,2`" = "s3" ]; then
  DEST_IS_S3=true
  S3CMD="$(which s3cmd)"
  if [ ! -x "$S3CMD" ]; then
    echo $NO_S3CMD; S3CMD_AVAIL=false
  elif [ -z "$S3CMD_CONF_FILE" -a ! -f "${HOME}/.s3cfg" ]; then
    echo $NO_S3CMD_CFG; S3CMD_AVAIL=false
  elif [ ! -z "$S3CMD_CONF_FILE" -a ! -f "$S3CMD_CONF_FILE" ]; then
    echo "${S3CMD_CONF_FILE} not found, check S3CMD_CONF_FILE variable in duplicity-backup's configuration!";
    echo $NO_S3CMD_CFG;
    S3CMD_AVAIL=false
  else
    S3CMD_AVAIL=true

    if [ ! -z "$S3CMD_CONF_FILE" -a -f "$S3CMD_CONF_FILE" ]; then
      S3CMD="${S3CMD} -c ${S3CMD_CONF_FILE}"
    fi
  fi
else
  DEST_IS_S3=false
fi

config_sanity_fail()
{
  EXPLANATION=$1
  CONFIG_VAR_MSG="Oops!! ${0} was unable to run!\nWe are missing one or more important variables in the configuration file.\nCheck your configuration because it appears that something has not been set yet."
  echo -e "${CONFIG_VAR_MSG}\n  ${EXPLANATION}."
  exit 1
}

check_variables ()
{
  [[ ${ROOT} = "" ]] && config_sanity_fail "ROOT must be configured"
  [[ ${DEST} = "" || ${DEST} = "s3+http://backup-foobar-bucket/backup-folder/" ]] && config_sanity_fail "DEST must be configured"
  [[ ${INCLIST} = "/home/foobar_user_name/Documents/" ]] && config_sanity_fail "INCLIST must be configured" 
  [[ ${EXCLIST} = "/home/foobar_user_name/Documents/foobar-to-exclude" ]] && config_sanity_fail "EXCLIST must be configured" 
  [[ ( ${ENCRYPTION} = "yes" && (${GPG_ENC_KEY} = "foobar_gpg_key" || \
       ${GPG_SIGN_KEY} = "foobar_gpg_key" || \
       ${PASSPHRASE} = "foobar_gpg_passphrase")) ]] && \
  config_sanity_fail "ENCRYPTION is set to 'yes', but GPG_ENC_KEY, GPG_SIGN_KEY, or PASSPHRASE have not been configured"
  [[ ${LOGDIR} = "/home/foobar_user_name/logs/test2/" ]] && config_sanity_fail "LOGDIR must be configured"
  [[ ( ${DEST_IS_S3} = true && (${AWS_ACCESS_KEY_ID} = "foobar_aws_key_id" || ${AWS_SECRET_ACCESS_KEY} = "foobar_aws_access_key" )) ]] && \
  config_sanity_fail "An s3 DEST has been specified, but AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY have not been configured"
}

check_logdir()
{
  if [ ! -d ${LOGDIR} ]; then
    echo "Attempting to create log directory ${LOGDIR} ..."
    if ! mkdir -p ${LOGDIR}; then
      echo "Log directory ${LOGDIR} could not be created by this user: ${USER}"
      echo "Aborting..."
      exit 1
    else
      echo "Directory ${LOGDIR} successfully created."
    fi
  elif [ ! -w ${LOGDIR} ]; then
    echo "Log directory ${LOGDIR} is not writeable by this user: ${USER}"
    echo "Aborting..."
    exit 1
  fi
}

email_logfile()
{
  if [ ! -z "$EMAIL_TO" ]; then
      MAILCMD=$(which $MAIL)
      if [ ! -x "$MAILCMD" ]; then
          echo -e "Email couldn't be sent. ${MAIL} not available." >> ${LOGFILE}
      else
          EMAIL_SUBJECT=${EMAIL_SUBJECT:="duplicity-backup alert ${LOG_FILE}"}
          if [ "$MAIL" = "ssmtp" ]; then
            echo """Subject: ${EMAIL_SUBJECT}""" | cat - ${LOGFILE} | ${MAILCMD} -s ${EMAIL_TO}
          elif [ "$MAIL" = "msmtp" ]; then
            echo """Subject: ${EMAIL_SUBJECT}""" | cat - ${LOGFILE} | ${MAILCMD} ${EMAIL_TO}
          elif [ "$MAIL" = "mailx" ]; then
            EMAIL_FROM=${EMAIL_FROM:+"-r ${EMAIL_FROM}"}
            cat ${LOGFILE} | ${MAILCMD} -s """${EMAIL_SUBJECT}""" $EMAIL_FROM ${EMAIL_TO}
          elif [ "$MAIL" = "mail" ]; then
            if [[ `uname` == "FreeBSD" || `uname` == 'Darwin' ]]; then
               cat ${LOGFILE} | ${MAILCMD} -s """${EMAIL_SUBJECT}""" ${EMAIL_TO} --
            else
               cat ${LOGFILE} | ${MAILCMD} -s """${EMAIL_SUBJECT}""" $EMAIL_FROM ${EMAIL_TO} -- -f ${EMAIL_FROM}
            fi
          elif [[ "$MAIL" = "sendmail" ]]; then
            (echo """Subject: ${EMAIL_SUBJECT}""" ; cat ${LOGFILE}) | ${MAILCMD} -f ${EMAIL_FROM} ${EMAIL_TO}
          elif [ "$MAIL" = "nail" ]; then
            cat ${LOGFILE} | ${MAILCMD} -s """${EMAIL_SUBJECT}""" $EMAIL_FROM ${EMAIL_TO}
          fi
          echo -e "Email alert sent to ${EMAIL_TO} using ${MAIL}" >> ${LOGFILE}
      fi
  fi
}

get_lock()
{
  echo "Attempting to acquire lock ${LOCKFILE}" >> ${LOGFILE}
  if ( set -o noclobber; echo "$$" > "${LOCKFILE}" ) 2> /dev/null; then
      # The lock succeeded. Create a signal handler to remove the lock file when the process terminates.
      trap 'EXITCODE=$?; echo "Removing lock. Exit code: ${EXITCODE}" >>${LOGFILE}; rm -f "${LOCKFILE}"' 0
      echo "successfully acquired lock." >> ${LOGFILE}
  else
      # Write lock acquisition errors to log file and stderr
      echo "lock failed, could not acquire ${LOCKFILE}" | tee -a ${LOGFILE} >&2
      echo "lock held by $(cat ${LOCKFILE})" | tee -a ${LOGFILE} >&2
      email_logfile
      exit 2
  fi
}

get_source_file_size()
{
  echo "---------[ Source File Size Information ]---------" >> ${LOGFILE}

  # Patches to support spaces in paths-
  # Remove space as a field separator temporarily
  OLDIFS=$IFS
  IFS=$(echo -en "\t\n")

  DUEXCFLAG="--exclude-from="
  if [[ `uname` == 'FreeBSD' || `uname` == 'Darwin' ]]; then
     DUEXCFLAG="-I "
  fi

  for exclude in ${EXCLIST[@]}; do
    DUEXCLIST="${DUEXCLIST}${exclude}\n"
  done

  for include in ${INCLIST[@]}
    do
      echo -e '"'$DUEXCLIST'"' | \
      du -hs ${DUEXCFLAG}"-" ${include} | \
      awk '{ FS="\t"; $0=$0; print $1"\t"$2 }' \
      >> ${LOGFILE}
  done
  echo >> ${LOGFILE}

  # Restore IFS
  IFS=$OLDIFS
}

get_remote_file_size()
{
  echo "------[ Destination File Size Information ]------" >> ${LOGFILE}

  dest_type=`echo ${DEST} | cut -c 1,2`
  case $dest_type in
    "fi")
      TMPDEST=`echo ${DEST} | cut -c 6-`
      SIZE=`du -hs ${TMPDEST} | awk '{print $1}'`
    ;;
    "s3")
      if $S3CMD_AVAIL ; then
          TMPDEST=$(echo ${DEST} | cut -c 11-)
          dest_scheme=$(echo ${DEST} | cut -f -1 -d :)
          if [ "$dest_scheme" = "s3" ]; then
              # Strip off the host name, too.
              TMPDEST=`echo $TMPDEST | cut -f 2- -d /`
          fi
          SIZE=`${S3CMD} du -H s3://${TMPDEST} | awk '{print $1}'`
      else
          SIZE="s3cmd not installed."
      fi
    ;;
    *)
      SIZE="Information on remote file size unavailable."
    ;;
  esac

  echo "Current Remote Backup File Size: ${SIZE}" >> ${LOGFILE}
  echo >> ${LOGFILE}
}

include_exclude()
{
  # Changes to handle spaces in directory names and filenames
  # and wrapping the files to include and exclude in quotes.
  OLDIFS=$IFS
  IFS=$(echo -en "\t\n")

  for include in ${INCLIST[@]}
  do
    TMP=" --include=""'"$include"'"
    INCLUDE=$INCLUDE$TMP
  done

  for exclude in ${EXCLIST[@]}
  do
    TMP=" --exclude ""'"$exclude"'"
    EXCLUDE=$EXCLUDE$TMP
  done
  
  # INCLIST is empty so every file needs to be saved
  if [[ "$INCLIST" == '' ]]; then
    EXCLUDEROOT=''
  else
    EXCLUDEROOT="--exclude=**"
  fi

  # Restore IFS
  IFS=$OLDIFS
}

duplicity_cleanup()
{
  echo "-----------[ Duplicity Cleanup ]-----------" >> ${LOGFILE}
  eval ${ECHO} ${DUPLICITY} ${CLEAN_UP_TYPE} ${CLEAN_UP_VARIABLE} ${STATIC_OPTIONS} --force \
      ${ENCRYPT} \
      ${DEST} >> ${LOGFILE}
  echo >> ${LOGFILE}
  if [ ! -z ${REMOVE_INCREMENTALS_OLDER_THAN} ] && [[ ${REMOVE_INCREMENTALS_OLDER_THAN} =~ ^[0-9]+$ ]]; then
    eval ${ECHO} ${DUPLICITY} remove-all-inc-of-but-n-full ${REMOVE_INCREMENTALS_OLDER_THAN} \
      ${STATIC_OPTIONS} --force \
      ${ENCRYPT} \
      ${DEST} >> ${LOGFILE}
    echo >> ${LOGFILE}
  fi  
}

duplicity_backup()
{
  eval ${ECHO} ${DUPLICITY} ${OPTION} ${VERBOSITY} ${STATIC_OPTIONS} \
  ${ENCRYPT} \
  ${EXCLUDE} \
  ${INCLUDE} \
  ${EXCLUDEROOT} \
  ${ROOT} ${DEST} \
  >> ${LOGFILE}
}

setup_passphrase()
{
  if [ ! -z "$GPG_ENC_KEY" -a ! -z "$GPG_SIGN_KEY" -a "$GPG_ENC_KEY" != "$GPG_SIGN_KEY" ]; then
    echo -n "Please provide the passphrase for decryption (GPG key 0x${GPG_ENC_KEY}): "
    builtin read -s ENCPASSPHRASE
    echo -ne "\n"
    PASSPHRASE=$ENCPASSPHRASE
    export PASSPHRASE
  fi
}

get_file_sizes()
{
  get_source_file_size
  get_remote_file_size

  sed -i -e '/^--*$/d' ${LOGFILE}
  chown ${LOG_FILE_OWNER} ${LOGFILE}
}

backup_this_script()
{
  if [ `echo ${0} | cut -c 1` = "." ]; then
    SCRIPTFILE=$(echo ${0} | cut -c 2-)
    SCRIPTPATH=$(pwd)${SCRIPTFILE}
  else
    SCRIPTPATH=$(which ${0})
  fi
  TMPDIR=duplicity-backup-`date +%Y-%m-%d`
  TMPFILENAME=${TMPDIR}.tar.gpg
  README=${TMPDIR}/README

  echo "You are backing up: "
  echo "      1. ${SCRIPTPATH}"

  if [ ! -z "$GPG_ENC_KEY" -a ! -z "$GPG_SIGN_KEY" ]; then
    if [ "$GPG_ENC_KEY" = "$GPG_SIGN_KEY" ]; then
      echo "      2. GPG Secret encryption and sign key: ${GPG_ENC_KEY}"
    else
      echo "      2. GPG Secret encryption key: ${GPG_ENC_KEY} and GPG secret sign key: ${GPG_SIGN_KEY}"
    fi
  else
    echo "      2. GPG Secret encryption and sign key: none (symmetric encryption)"
  fi

  if [ ! -z "$CONFIG" -a -f "$CONFIG" ];
  then
    echo "      3. Config file: ${CONFIG}"
  fi

  echo "Backup tarball will be encrypted and saved to: `pwd`/${TMPFILENAME}"
  echo
  echo ">> Are you sure you want to do that ('yes' to continue)?"
  read ANSWER
  if [ "$ANSWER" != "yes" ]; then
    echo "You said << ${ANSWER} >> so I am exiting now."
    exit 1
  fi

  mkdir -p ${TMPDIR}
  cp $SCRIPTPATH ${TMPDIR}/

  if [ ! -z "$CONFIG" -a -f "$CONFIG" ];
  then
    cp $CONFIG ${TMPDIR}/
  fi

  if [ ! -z "$GPG_ENC_KEY" -a ! -z "$GPG_SIGN_KEY" ]; then
    export GPG_TTY=`tty`
    if [ "$GPG_ENC_KEY" = "$GPG_SIGN_KEY" ]; then
      gpg -a --export-secret-keys ${GPG_ENC_KEY} > ${TMPDIR}/duplicity-backup-encryption-and-sign-secret.key.txt
    else
      gpg -a --export-secret-keys ${GPG_ENC_KEY} > ${TMPDIR}/duplicity-backup-encryption-secret.key.txt
      gpg -a --export-secret-keys ${GPG_SIGN_KEY} > ${TMPDIR}/duplicity-backup-sign-secret.key.txt
    fi
  fi

  echo -e ${README_TXT} > ${README}
  echo "Encrypting tarball, choose a password you'll remember..."
  tar c ${TMPDIR} | gpg -aco ${TMPFILENAME}
  rm -Rf ${TMPDIR}
  echo -e "\nIMPORTANT!!"
  echo ">> To restore these files, run the following (remember your password):"
  echo "gpg -d ${TMPFILENAME} | tar x"
  echo -e "\nYou may want to write the above down and save it with the file."
}

check_variables
check_logdir

echo -e "--------    START DUPLICITY-BACKUP SCRIPT    --------\n" >> ${LOGFILE}

get_lock

INCLUDE=
EXCLUDE=
EXCLUDEROOT=

case "$COMMAND" in
  "backup-script")
    backup_this_script
    exit
  ;;

  "full")
    OPTION="full"
    include_exclude
    duplicity_backup
    duplicity_cleanup
    get_file_sizes
  ;;

  "verify")
    OLDROOT=${ROOT}
    ROOT=${DEST}
    DEST=${OLDROOT}
    OPTION="verify"

    echo -e "-------[ Verifying Source & Destination ]-------\n" >> ${LOGFILE}
    include_exclude
    setup_passphrase
    echo -e "Attempting to verify now ..."
    duplicity_backup

    OLDROOT=${ROOT}
    ROOT=${DEST}
    DEST=${OLDROOT}

    get_file_sizes

    echo -e "Verify complete.  Check the log file for results:\n>> ${LOGFILE}"
  ;;

  "restore")
    ROOT=$DEST
    OPTION="restore"
    if [ ! -z "$TIME" ]; then
      STATIC_OPTIONS="$STATIC_OPTIONS --time $TIME"
    fi

    if [[ ! "$RESTORE_DEST" ]]; then
      echo "Please provide a destination path (eg, /home/user/dir):"
      read -e NEWDESTINATION
      DEST=$NEWDESTINATION
      echo ">> You will restore from ${ROOT} to ${DEST}"
      echo "Are you sure you want to do that ('yes' to continue)?"
      read ANSWER
      if [[ "$ANSWER" != "yes" ]]; then
        echo "You said << ${ANSWER} >> so I am exiting now."
        echo -e "User aborted restore process ...\n" >> ${LOGFILE}
        exit 1
      fi
    else
      DEST=$RESTORE_DEST
    fi

    setup_passphrase
    echo "Attempting to restore now ..."
    duplicity_backup
  ;;

  "restore-file"|"restore-dir")
    ROOT=$DEST
    OPTION="restore"

    if [ ! -z "$TIME" ]; then
      STATIC_OPTIONS="$STATIC_OPTIONS --time $TIME"
    fi

    if [[ ! "$FILE_TO_RESTORE" ]]; then
      echo "Which file or directory do you want to restore?"
      echo "(give the path relative to the root of the backup eg, mail/letter.txt):"
      read -e FILE_TO_RESTORE
      echo
    fi

    if [[ "$RESTORE_DEST" ]]; then
      DEST=$RESTORE_DEST
    else
      DEST=$(basename $FILE_TO_RESTORE)
    fi

    echo -e "YOU ARE ABOUT TO..."
    echo -e ">> RESTORE: $FILE_TO_RESTORE"
    echo -e ">> TO: ${DEST}"
    echo -e "\nAre you sure you want to do that ('yes' to continue)?"
    read ANSWER
    if [ "$ANSWER" != "yes" ]; then
      echo "You said << ${ANSWER} >> so I am exiting now."
      echo -e "--------    END    --------\n" >> ${LOGFILE}
      exit 1
    fi

    FILE_TO_RESTORE="'"$FILE_TO_RESTORE"'"
    DEST="'"$DEST"'"

    setup_passphrase
    echo "Restoring now ..."
    #use INCLUDE variable without creating another one
    INCLUDE="--file-to-restore ${FILE_TO_RESTORE}"
    duplicity_backup
  ;;

  "list-current-files")
    OPTION="list-current-files"

    if [ ! -z "$TIME" ]; then
      STATIC_OPTIONS="$STATIC_OPTIONS --time $TIME"
    fi

    ${DUPLICITY} ${OPTION} ${VERBOSITY} ${STATIC_OPTIONS} \
    $ENCRYPT \
    ${DEST} | tee -a ${LOGFILE}
    echo -e "--------    END    --------\n" >> ${LOGFILE}
  ;;

  "collection-status")
    OPTION="collection-status"
    ${DUPLICITY} ${OPTION} ${VERBOSITY} ${STATIC_OPTIONS} \
    $ENCRYPT \
    ${DEST} | tee -a ${LOGFILE}
    echo -e "--------    END    --------\n" >> ${LOGFILE}
  ;;

  "backup")
    include_exclude
    duplicity_backup
    duplicity_cleanup
    get_file_sizes
  ;;

  *)
    echo -e "[Only show `basename $0` usage options]\n" >> ${LOGFILE}
    usage
  ;;
esac

echo -e "--------    END DUPLICITY-BACKUP SCRIPT    --------\n" >> ${LOGFILE}

email_logfile

if [ ${ECHO} ]; then
  echo "TEST RUN ONLY: Check the logfile for command output."
fi

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset PASSPHRASE
unset SIGN_PASSPHRASE

# vim: set tabstop=2 shiftwidth=2 sts=2 autoindent smartindent:
