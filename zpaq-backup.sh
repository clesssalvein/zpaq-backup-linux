#!/bin/bash

###
# ZPAQ-BACKUP - archiving multiple directories with unpacking for checking
# by Cless
#
# Requirements:
# * change list of bases for backup (with full paths) in the file dbsList.txt. it must be filled in manually
# * change var's paths in "paths" section
###


# ---
# VARS
# ---

# paths
rootDir="/root/backup-zpaq"
zpaq=${rootDir}/zpaq/zpaq
dbsBackupDir=${rootDir}/dbs_backup
dbsExtractedForCheckDir=${rootDir}/dbs_extracted_for_check
dbsLogDir=${rootDir}/dbs_log
dbsBackupLogFile=${dbsLogDir}/dbsBackupLog.txt
dbsBackupStatusFile=${dbsLogDir}/dbsBackupStatus.txt
dbsListDir=${rootDir}
dbsListFile=${dbsListDir}/dbsList.txt
checkMarkerFileName="checkMarker.txt"

# utils
mkdir=`which mkdir`

# dateCurrent (YYYY-mm-dd)
dateCurrent=`date +%Y-%m-%d`


# ---
# COMMON ACTIONS
# ---

## create dbsList dir
#if ! [ -d "${dbsListDir}" ]; then
#        ${mkdir} -p ${dbsListDir}
#fi

# create log dir
if ! [ -d "${dbsLogDir}" ]; then
        ${mkdir} -p "${dbsLogDir}"
fi

# delete backup log file
if test -f "${dbsBackupLogFile}"; then
    rm -f "${dbsBackupLogFile}"
fi

# delete backup status file
if test -f "${dbsBackupStatusFile}"; then
    rm -f "${dbsBackupStatusFile}"
fi

# create array of db names with paths from db list file
arrayDbsList=()
while IFS= read -r line;
  do
    arrayDbsList+=( "$line" )
  done < <( cat "${dbsListFile}" )

# debug
echo "Number of elements (DBs) in array: ${#arrayDbsList[*]}"


# ---
# FOR EVERY DB NAME WITH FULL PATH FROM DBSLIST.TXT DO:
# ---

for dbNameWithPath in "${arrayDbsList[@]}";
do
    # debug
    echo "dbNameWithPath: ${dbNameWithPath}"

    # get db name without path and get db path
    dbName=${dbNameWithPath##*/}
    dbPath=${dbNameWithPath%/*}

    # debug
    echo "dbName: ${dbName}"
    echo "dbPath: ${dbPath}"


    # ---
    # ARCH DB
    # ---

    # delete chk marker
    if test -f "${dbNameWithPath}/${checkMarkerFileName}"; then
        rm -rf "${dbNameWithPath}/${checkMarkerFileName}"
    fi

    # create chk marker in db
    echo ${dateCurrent} > "${dbNameWithPath}/${checkMarkerFileName}"

    # create root dir for db in common backup dir
    if ! [ -d "${dbsBackupDir}/${dbName}" ]; then
        ${mkdir} -p "${dbsBackupDir}/${dbName}"
    fi

    # arch db
    cd "${dbPath}"
    ${zpaq} a "${dbsBackupDir}/${dbName}/${dbName}_???.zpaq" "${dbName}"

    # get dbArchStatus
    if [[ $? == "0" ]]; then
        echo "-ARCH_OK-";
        dbArchStatus="-ARCH_OK-"
    else
        echo "-ARCH_FAIL-";
        dbArchStatus="-ARCH_FAIL-"
    fi

    # delete chk marker in source db
    if test -f "${dbNameWithPath}/${checkMarkerFileName}"; then
        rm -rf "${dbNameWithPath}/${checkMarkerFileName}"
    fi


    # ---
    # EXTRACT DB FOR CHECK
    # ---

    # create dbsExtractedForCheckDir
    if ! [ -d "${dbsExtractedForCheckDir}" ]; then
        ${mkdir} -p "${dbsExtractedForCheckDir}"
    fi

    # delete every extracted for check db
    if ! [ -d "${dbsExtractedForCheckDir}/${dbName}" ]; then
        rm -rf "${dbsExtractedForCheckDir}/${dbName}"
    fi

    # extract db
    cd "${dbsBackupDir}/${dbName}"
    ${zpaq} x "${dbName}_???.zpaq" -force -to "${dbsExtractedForCheckDir}"

    # get dbExtrStatus
    if [[ $? == "0" ]]; then
        echo "-EXTRACT_OK-";
        dbExtrStatus="-EXTRACT_OK-"
    else
        echo "-EXTRACT_FAIL-";
        dbExtrStatus="-EXTRACT_FAIL-"
    fi

    # find currentdate in db marker file
    cat "${dbsExtractedForCheckDir}/${dbName}/${checkMarkerFileName}" | grep "${dateCurrent}"

    # if
        if [[ $? == "0" ]]; then
        echo "-CHECKMARKER_OK-";
        dbCheckMarkerStatus="-CHECKMARKER_OK-"
    else
        echo "-CHECKMARKER_FAIL-";
        dbCheckMarkerStatus="-CHECKMARKER_FAIL-"
    fi

    # write backup log
    echo ${dbNameWithPath} : ${dbArchStatus} ${dbExtrStatus} ${dbCheckMarkerStatus} >> ${dbsBackupLogFile}
done

# IF there's BACKUP_FAIL in log file - write FAIL into status file
if [[ -n `cat "${dbsBackupLogFile}" | grep "_FAIL-"` ]]; then
    echo "-BACKUP_FAIL-";

    # write OK backup status
    echo "FAIL" > ${dbsBackupStatusFile}
else
    # IF there's BACKUP_OK in log file - write OK into status file
    if [[ -n `cat "${dbsBackupLogFile}" | grep "_OK-"` ]]; then
        echo "-BACKUP_OK-"

        # write FAIL backup status
        echo "OK" > ${dbsBackupStatusFile}
    else
        echo "-BACKUP_FAIL-"

        # backup log
        echo "FAIL" > ${dbsBackupStatusFile}
    fi
fi
