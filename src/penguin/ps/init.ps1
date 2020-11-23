& {
    BEGIN {
        $S3BucketUrl = {{S3_BUCKET_URL}}
        $S3BucketFolder = {{S3_BUCKET_FOLDER}}
        $LocalScriptFolder = "C:\Configuration"
        $LocalWwwrootFolder = "C:\inetpub\wwwroot\index.html"
        $EventLogSource = "Cover-More SOE Customisation"

        Import-Module Microsoft.PowerShell.Management
        if (-not ([System.Diagnostics.EventLog]::SourceExists($EventLogSource))) {
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
            Write-EventLog -LogName "Application" -Source $EventLogSource -EntryType $type -EventID 1 -Category 1 -Message $msg 
            Write-Output "$type`t`t$msg"
        }

        log -msg "$(if ($PSCommandPath) { "'$PSCommandPath'" } else { "Initialisation" }) has started."
    }

    PROCESS {
        try {
            # Ensure we have prerequisite modules/features available
            # Check that the AWS.Tools.S3 module is available:
            if ($null -eq $(Get-Module AWS.Tools.S3)) {
                log "Warn" "PowerShell Module 'AWS.Tools.S3' needs to be installed & available for this script to function. Installing now."
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force;
                Install-Module -Name AWS.Tools.S3 -Force;
                Import-Module -Name AWS.Tools.S3;
            }
            log -msg "[✔] PowerShell Module 'AWS.Tools.S3' availability has been confirmed."
    
            # Check that IIS is installed/enabled
            if ($(Get-WindowsFeature Web-Server).InstallState -ne "Installed") {
                log "Warn" "Windows Feature 'Web-Server' needs to be enabled for the healthchecks to work. Configuring now."
                Install-WindowsFeature Web-Server -IncludeManagementTools;
            }
            log -msg "[✔] IIS has been enabled."

            # Make sure there is a basic index.html available to answer requests
            if (-not (Get-Item -Path $LocalWwwrootFolder)) {
                Write-Output "<h1>Hello World</h1>" | Out-File -FilePath $LocalWwwrootFolder;
                log -msg "[✔] 'Hello World' index.html dumped to local wwwroot folder: '$LocalWwwrootFolder'."
            }
            $response = (Invoke-WebRequest "http://localhost" -UseBasicParsing);
            log -msg "[✔] Basic request to 'http://localhost' returned the following: '$($response.StatusCode) $($response.StatusDescription)'"

            # Double-check that we have the AWS functions available:
            log -msg "AWSPowerShellVersion Info:`n$(Get-AWSPowerShellVersion -ListServiceVersionInfo)"

            # Download the contents of the configuration bucket
            if (Get-S3Object -BucketName $S3BucketUrl) {
                Read-S3Object -BucketName $S3BucketUrl -KeyPrefix $S3BucketFolder -Folder $LocalScriptFolder
                log -msg "[✔] The contents of the folder '$S3BucketFolder' in the S3Bucket '$S3BucketUrl' have been downloaded to '$LocalScriptFolder'."
            }
            else {
                log "Error" "[❌] S3 Bucket at '$S3BucketUrl' is not accessible."
            }
            
            # Load Environment Variables if they are defined/available
            $EnvVarsFile = (Join-Path $LocalScriptFolder "_env.ps1")
            if (Test-Path $EnvVarsFile) { 
                . $EnvVarsFile; 
                log -msg "[✔] Environment variables were loaded from file: '$EnvVarsFile'."; 
            } else {
                # Load known environment variables for downloaded scripts:
                $ENV:NessusKey = {{NESSUS_KEY}}
                $ENV:NessusGroups = "IRE-CM-LZ"
                $ENV:NessusServer = "cloud.tenable.com"
                $ENV:OctopusServerUrl = "octopus.covermore.com"
                $ENV:OctopusServerApiKey = {{OCTOSERVER_APIKEY}}
                $ENV:OctopusServerThumbprint = {{OCTOSERVER_THUMB}}
                $ENV:OctopusTentacleInstanceName = $null # will default to instance name
                $ENV:OctopusTentaclePort = 10933
                $ENV:OctopusTentacleRootFolder = "C:\Octopus"
                $ENV:OctopusTentacleRoles = @("")
                $ENV:OctopusTentacleEnvironment = "Dev1"
                log "Warn" "Environment variables were loaded directly from the inline script.";
            }

            # Run each script that was downloaded
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
        log -msg "$(if ($PSCommandPath) { "'$PSCommandPath'" } else { "Initialisation" }) has completed successfully."
    }
};