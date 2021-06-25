Developer - K.Janarthanan

1. Fill the Config.Json as per the requirements
2. The script will create a log file in the same folder location

Notes
-------
A) Make sure the file name must be in the pattern "*backup_dd_MMM_yy_HH_mm_ss_SQL.bak", as I am
splitting the file name between "backup" and "SQL.bak" words

B) Test the script in DEV before moving to production

C) PowerShell command to create scheduled tasks,

$script_args="-nologo -noninteractive -noprofile -ExecutionPolicy BYPASS -file Folder\Move_Backup.ps1"
$action=New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument $script_args
$trigger= New-ScheduledTaskTrigger -Daily -At “10:30”
$principal=New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType S4U -RunLevel Highest
$STSet = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName “Backup_Script” -TaskPath “\backup_script” -Trigger $trigger -Action $action -Description “This script is used for moving SQL backups” -Principal $principal -Settings $STSet -Force

