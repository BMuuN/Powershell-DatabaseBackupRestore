<#
    Title:
        Restore Database

    Created By:
        Bleddyn Richards

    Description:
        Restore database backup (*.bak) from a local or network location to your local SQL 2014 instance.

    Notes:
        Please run this script in user mode.  Do not run this acript as an Administrator!
#>

# Remove SQL 2012 from the Environment Variable
Write-Host "Removing SQL Server 2012 from the PowerShell Environment Variable..."
$TempArray = @()
$TempArray = $env:PSModulePath -split ';'
# 110 for SQL 2012, 120 for SQL 2014, 130 for SQL 2016
$env:PSModulePath = ($TempArray -notmatch '110') -join ';' 

# Import the SQL modules
Import-Module sqlps

# Set SQL Data File Location
Write-Host "Realocating the SQL Data Files.."
$RelocateData = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile("ContosoUniversity", "C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER2014\MSSQL\DATA\ContosoUniversity.mdf")
$RelocateData2 = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile("ContosoUniversity2", "C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER2014\MSSQL\DATA\ContosoUniversity_1.ndf")
$RelocateLog = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile("ContosoUniversity_Log", "C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER2014\MSSQL\DATA\ContosoUniversity_log.ldf")
#$file = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile($RelocateData, $RelocateLog)
$myarr = @($RelocateData, $RelocateData2, $RelocateLog)

#$RelocateData = New-Object 'Microsoft.SqlServer.Management.Smo.RelocateFile, Microsoft.SqlServer.SmoExtended, Version=12.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91' -ArgumentList "ContosoUniversity", "C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER2014\MSSQL\DATA\ContosoUniversity.mdf"
#$RelocateData2 = New-Object 'Microsoft.SqlServer.Management.Smo.RelocateFile, Microsoft.SqlServer.SmoExtended, Version=12.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91' -ArgumentList "ContosoUniversity2", "C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER2014\MSSQL\DATA\ContosoUniversity_1.mdf"
#$RelocateLog = New-Object 'Microsoft.SqlServer.Management.Smo.RelocateFile, Microsoft.SqlServer.SmoExtended, Version=12.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91' -ArgumentList "ContosoUniversity_Log", "C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER2014\MSSQL\DATA\ContosoUniversity_log.ldf"
#$file = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile($RelocateData, $RelocateLog)
#$myarr = @($RelocateData, $RelocateData2, $RelocateLog)

# Copy the backup to the users local machine
cd c: # This is critical for copying files from a UNC
$saveLocation = "C:\DB_BACKUPS"
$backupLocation = "\\SqlShare\ContosoUniversity\"
$latest = Get-ChildItem -Path $backupLocation -Name "*.bak" | Sort-Object LastAccessTime -Descending | Select-Object -First 1

# Create 'C:\DB_BACKUPS' directory
if (-Not (Test-Path $saveLocation)) {
    Write-Host "Creating temp folder ($saveLocation)..."
    MD $saveLocation
}

#Write-Host "Backup:  $backupLocation\$latest"
#Write-Host "Save:  $saveLocation\$latest"

# Copy the backup from the network to the local machine
if (-Not (Test-Path "$saveLocation\$latest")) {
    Write-Host "Getting the latest backup ($latest)..."
    Copy-Item -path "$backupLocation\$latest" "$saveLocation\$latest" > $null
}

Write-Host "Restore $latest to your local SQL 2014 server..."

# Local Backup
Restore-SqlDatabase -ServerInstance ".\MSSQLSERVER2014" -Database "ContosoUniversity" -BackupFile "$saveLocation\$latest" -RelocateFile $myarr -ReplaceDatabase -Verbose

# Network Backup
#Restore-SqlDatabase -ServerInstance ".\MSSQLSERVER2014" -Database "ContosoUniversity" -BackupFile "$backupLocation\$latest" -RelocateFile $myarr -ReplaceDatabase -Verbose

# clean up the C:\DB_BACKUPS directory: - only leave the last 3 backups in the folder
$backupCount = (Get-ChildItem -Path $saveLocation -Name "*.bak" | Sort-Object LastModifiedTime -Descending | Measure-Object).Count
if ($backupCount -gt 3) {
    Write-Host "Removing old backups from $saveLocation..."
    $totalBackupsToRemove = ($backupCount - 3)
    $backupFiles = Get-ChildItem -Path $saveLocation -Name "*.bak" | Sort-Object LastModifiedTime | Select-Object -Last $totalBackupsToRemove
    foreach ($file in $backupFiles)
    {
        Write-Host "`tRemoving: $file"
        Remove-Item -Force "$saveLocation\$file"
    }
}

Write-Host ""
Write-Host "Complete!"
Exit
