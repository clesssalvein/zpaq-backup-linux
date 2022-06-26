# About
ZPAQ is an open source command line archiver for Windows and Linux. It uses a journaling or append-only format which can be rolled back to an earlier state to retrieve older versions of files and directories (https://en.wikipedia.org/wiki/ZPAQ).

Website: http://mattmahoney.net/dc/zpaq.html

# Description
This system is intended for incremental archiving and long-term storage of archives (databases) and verification of created archives in Linux OS.

The system includes:
- Directory with "zpaq" application
- Main script "zpaq-backup.sh"
- File containing a list of databases "dbsList.txt"
- Dynamically created directories:
  - "dbs_backup" - to store created archives
  - "dbs_extracted_for_check" to extract and check generated archives
  - "dbs_log" for logging and backup status

# Installation
- On the server (Linux OS) where the backup system will be used:
  - Fill in the list of directories (bases) for backup (absolute paths are required) in the dbsList.txt file. Example:
    ```
    /tmp/dbs/db01
    /tmp/dbs/dir02
    ```
  - Change the paths directories, files and utilities in the "paths" section of the "zpaq-backup.sh" file
  - Run "zpaq-backup.sh"

# Work algorithm
- The zpaq-backup.sh script gets a list of directories (bases) from file "dbsList.txt"
- Actions are performed for each directory:
  - File "checkMarker.txt" containing the current date in format **YYYY-mm-dd** is written to the directory
  - Directory is archived along the path dbs_backup/{dbName}/ with the archive name {dbName}_???.zpaq, where ??? - sequence number of the archive (001 - full archive, the following ones are incremental)
  - Upon completion of the archiving, the status of the operation is written to the "dbArchStatus" variable (**-ARCH_OK-** | **-ARCH_FAIL-**)
  - The file checkMarker.txt is removed from the directory
  - The archive is extracted along the path dbs_extracted_for_check/{dbName}
  - Upon completion of the extraction, the status of the operation is written to the dbExtrStatus variable (**-EXTRACT_OK-** | **-EXTRACT_FAIL-**)
  - The dbs_extracted_for_check/{dbName}/checkMarker.txt file is checked to see if it contains the current date in **YYYY-mm-dd** format. As a result, dbCheckMarkerStatus is set to (**-CHECKMARKER_OK-** | **-CHECKMARKER_FAIL-**)
  - A line like this is written to the backup logging file "dbs_log/dbsBackupLog.txt":
    ```
    /tmp/dbs/!dbName! : -ARCH_OK- -EXTRACT_OK- -CHECKMARKER_OK-
    ```

- As a result, the following structure is created in the dbs_log\dbsBackupLog.txt file:
```
/tmp/dbs/db01 : -ARCH_OK- -EXTRACT_OK- -CHECKMARKER_OK-
/tmp/dbs/dir02 : -ARCH_OK- -EXTRACT_OK- -CHECKMARKER_OK-
```

- Checks for the presence of a sequence of characters in the file "dbs_log/dbsBackupLog.txt" (**_OK-** | **_FAIL-**)
- Depending on the result, **OK** or **FAIL** is written to the final backup status file "dbs_log/dbsBackupStatus.txt"
