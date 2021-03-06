<#
    Title:
        Save Database

    Created By:
        Bleddyn Richards
    
    Description:
        Save a  database backup (*.bak) from a SQL instance to it's local backup disk.
        For this script the backup disk is G:\DB_Backup.
#>
Import-Module sqlps

$dt = Get-Date -Format yyyyMMddHHmmss
$dbname = ""
$servername = ""

Backup-SqlDatabase -ServerInstance $servername -Database $dbname -BackupFile "G:\DB_Backup\$($dbname)_db_$($dt).bak"

Exit