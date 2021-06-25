<#
Purpose - To move N level of backup to destination
Date - 20/6/2021
Version - 1.0
#>

[CmdletBinding()]
param (
    [String]
    $ConfigFile="$PSScriptRoot\Config.json"
)

$Global:LogFile = "$PSScriptRoot\BK_Move.log"

function Write-Log
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Validateset("INFO","ERR","WARN")]
        [string]$Type="INFO"
    )

    if(-not(Test-Path -path $LogFile.Replace($LogFile.split("\")[-1],"")))
    {
        New-Item -Path $LogFile.Replace($LogFile.split("\")[-1],"") -ItemType "directory" -Force
    }

    $DateTime = Get-Date -Format "MM-dd-yyyy HH:mm:ss"
    $FinalMessage = "[{0}]::[{1}]::[{2}]" -f $DateTime,$Type,$Message

    $FinalMessage | Out-File -FilePath $LogFile -Append
}

try
{
    Write-Log "Script Started"

    $Config = Get-Content -Path $ConfigFile -ErrorAction Stop | ConvertFrom-Json

    if($Config.Folders)
    {
        foreach($Entry in $Config.Folders)
        {
            Write-Log "Working in Source Folder - $($Entry.Source)"

            try 
            {
                if(Test-Path -Path $Entry.Source)
                {
                    if(Test-Path -Path $Entry.Destination)
                    {
                        $AllFiles = Get-ChildItem -Path $Entry.Source -EA Stop

                        if(-not $AllFiles)
                        {
                            throw "No any files found in the source folder $($Entry.Source)"
                        }

                        $AllFiles_Array = @()

                        foreach($SourceFile in $AllFiles)
                        {
                          $AllFiles_Array +=  (($SourceFile.Name -split"backup_") -split "_SQL.bak")[1]
                        }

                        $AllFiles_Array = $AllFiles_Array | foreach-object{[datetime]::parseexact($_, 'dd_MMM_yy_HH_mm_ss', $null)} | Sort -Descending | Select-Object -First $Config.Backup_Count
                        $Filtered_Files = $AllFiles_Array | ForEach-Object{(Get-Date $_ -format 'dd_MMM_yy_HH_mm_ss').Tostring()}

                        #Delete all files in destination
                        Remove-Item -Path "$($Entry.Destination)\*" -Force -Recurse -EA Stop

                        foreach($FileEntry in $Filtered_Files)
                        {
                            $CopyFile = $AllFiles | Where-Object {$_.Name -like "*APP_$FileEntry*"}

                            if($CopyFile)
                            {
                                Write-Log "Copying file $($CopyFile.Name) to destination $($Entry.Destination)"
                                Copy-Item -Path $CopyFile.FullName -Destination $Entry.Destination -Force -EA Stop
                            }
                            else 
                            {
                                Write-Log "Unable to find any file with timestamp $FileEntry"    
                            }  
                        }
                        
                    }
                    else 
                    {
                        throw "Unable to find the Source Folder $($Entry.Destination)"
                    }
                }
                else 
                {
                    throw "Unable to find the Source Folder $($Entry.Source)"
                }
            }
            catch 
            {
                Write-Log "$_" -Type ERR
            }         
        }
    }
    else 
    {
        Write-Log "No any folders list specified"    
    }
}

catch
{
    Write-Log "$_" -Type ERR
}