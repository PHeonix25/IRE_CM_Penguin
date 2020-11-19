& {
    BEGIN {
        $S3BucketUrl = {{REPLACE_ME}}
        $S3BucketFolder = "soe_config"
        $EventLogSource = "Cover-More SOE Customisation"
        $LocalScriptFolder = "C:\Configuration"

        Import-Module Microsoft.PowerShell.Management -UseWindowsPowerShell
        if (-not (Get-EventLog -LogName Application -Source $EventLogSource)) {
            Write-Warning "Event log source not located, creating now."
            try {
                New-EventLog -LogName Application -Source $EventLogSource;
            }
            catch {
                Write-Error "Event log source could not be created. Please try again as an Administrator."
                return;
            }
        }
        function log { 
            param([System.Diagnostics.EventLogEntryType]$type = "Information", [string]$msg)
            Write-EventLog -LogName "Application" -Source $EventLogSource -EntryType $type –EventID 1 -Category 1 -Message $msg 
            Write-Output "$type`t`t$msg"
        }

        log -msg """$PSCommandPath"" has started."

        if ($null -eq $(Get-Module AWS.Tools.S3)) {
            log "Warn" "PowerShell Module 'AWS.Tools.S3' needs to be installed & available for this script to function. Installing now."
            Install-Module -Name AWS.Tools.Installer -Force;
            Install-AWSToolsModule AWS.Tools.S3 -Force;
        }
        log -msg "[✔] PowerShell Module 'AWS.Tools.S3' availability has been confirmed."
    }

    PROCESS {

        try {
            log -msg "AWSPowerShellVersion Info:`n$(Get-AWSPowerShellVersion -ListServiceVersionInfo)"

            # Download the contents of the configuration bucket
            if (Get-S3Object -BucketName $S3BucketUrl) {
                log -msg "[✔] Pretend I downloaded the contents of the bucket."
                Read-S3Object -BucketName $S3BucketUrl -KeyPrefix $S3BucketFolder -Folder $LocalScriptFolder
            } else {
                log "Error" "[❌] S3 Bucket at '$S3BucketUrl' is not accessible."
            }
            
            # Run each script that was downloaded into the folder
            foreach ($script in $(Get-ChildItem -Path $LocalScriptFolder)) {
                Start-Process -FilePath $script.FullName -Wait
                log -msg "[✔] Configuration script '$($script.FullName)' completed.";
            }
        }
        catch {
            log "Error" "[❌] An error occurred that could not be automatically resolved: $_"
            throw $_;
        }
    }

    END {
        log -msg "[✔] ""$PSCommandPath"" has completed successfully."
    }
};