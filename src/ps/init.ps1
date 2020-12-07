& {
    BEGIN {
        $S3BucketName = ${PenguinInfraBucketName}
        $S3BucketFolder = ${PenguinInfraBucketFolder}
        $LocalScriptFolder = "C:\Configuration"
        $LocalHelloWorldFile = "C:\inetpub\wwwroot\index.html"
        $EventLogSource = "Cover-More SOE Customisation";
        
        Import-Module AWSPowerShell
        Import-Module Microsoft.PowerShell.Management
        
        # WinServer AMI's don't always specify TLS1.2, & Powershell 5 still defaults to TLS1.0
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
        
        if (-not ([System.Diagnostics.EventLog]::SourceExists($EventLogSource))) {
            Write-Warning "Event log source not located, creating now."
            try {
                New-EventLog -LogName Application -Source $EventLogSource;
            }
            catch {
                Write-Error "[X] Event log source could not be created. Please try again as an Administrator."
                return;
            }
        }

        function log { 
            param([System.Diagnostics.EventLogEntryType]$type = "Information", [string]$msg)
            Write-EventLog -LogName "Application" -Source $EventLogSource -EntryType $type -EventID 1 -Message $msg 
            Write-Output "$type`t`t$msg"
        }

        log -msg "$(if ($PSCommandPath) { "'$PSCommandPath'" } else { "Initialisation" }) has started."
        log -msg "Known variables: `n S3BucketName: '$S3BucketName' `n S3BucketFolder: '$S3BucketFolder' `n LocalScriptFolder: '$LocalScriptFolder' `n EventLogSource: '$EventLogSource'";
    }

    PROCESS {
        try {
            ######################
            ## IIS health-checks: 
            ######################
            # Check that IIS is installed/enabled
            if ($(Get-WindowsFeature Web-Server).InstallState -ne "Installed") {
                log "Warn" "Windows Feature 'Web-Server' needs to be enabled for the healthchecks to work. Configuring now."
                Install-WindowsFeature Web-Server -IncludeManagementTools;
                log -msg "Windows Feature 'Web-Server' has been installed."
                Install-WindowsFeature Web-Mgmt-Tools;
                log -msg "Windows Feature 'Web-Mgmt-Tools' has been installed."
                Enable-WindowsOptionalFeature -Online -FeatureName "IIS-WebServer" -All;
                log -msg "Windows Feature 'IIS-WebServer' has been enabled."
            }
            log -msg "IIS has been enabled."

            # Make sure there is a basic index.html available to answer requests
            if (-not (Get-Item -Path $LocalHelloWorldFile)) {
                Write-Output "<h1>Hello World</h1>" | Out-File -FilePath $LocalHelloWorldFile;
                log -msg "'Hello World' index.html dumped to local wwwroot folder: '$LocalHelloWorldFile'."
            }
            $response = (Invoke-WebRequest "http://localhost" -UseBasicParsing);
            log -msg "Basic request to 'http://localhost' returned the following: '$($response.StatusCode) $($response.StatusDescription)'"

            #############################################
            ## AWS S3 downloading extended config files: 
            #############################################
            # Check that the AWS.Tools.S3 module is available:
            if ($null -eq $(Get-Command "Get-S3Object")) {
                log "Warn" "PowerShell Module 'AWS.Tools.S3' needs to be installed & available for this script to function. Installing now."
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force;
                log -msg "NuGet package provider has been installed."
                Install-Module -Name AWS.Tools.S3 -Force -AllowClobber;
                log -msg "PowerShell Module 'AWS.Tools.S3' has been installed."
                Import-Module -Name AWS.Tools.S3;
                log -msg "PowerShell Module 'AWS.Tools.S3' has been imported into this session."
            }
            else {
                log -msg "PowerShell Module 'AWS.Tools.S3' availability has been confirmed."
            }
            log -msg "AWSPowerShellVersion Info:`n$(Get-AWSPowerShellVersion -ListServiceVersionInfo)"

            # Download the contents of the configuration bucket
            if (-not $S3BucketName) {
                log "Error" "[X] The S3Bucket name variable was not defined. Please check the variables you provided in your RFC!"
            } elseif (Get-S3Object -BucketName $S3BucketName) {
                Read-S3Object -BucketName $S3BucketName -KeyPrefix $S3BucketFolder -Folder $LocalScriptFolder
                log -msg "The contents of the '$S3BucketFolder' folder in the '$S3BucketName' S3Bucket have been downloaded to '$LocalScriptFolder'."
            }
            else {
                log "Error" "[X] S3Bucket at '$S3BucketName' is not accessible. Please ensure that permissions are set correctly."
            }

            #############################################
            ## Execute extended SOE configuration files: 
            #############################################
            # Load Environment Variables if they are defined/available
            $EnvVarsFile = (Join-Path $LocalScriptFolder "_env.ps1")
            if (Test-Path $EnvVarsFile) { 
                log -msg "File '$EnvVarsFile' exists. Loading environment variables from it."; 
                . $EnvVarsFile; 
                log -msg "Environment variables were loaded from file: '$EnvVarsFile'."; 
            }
            else {
                log "Error" "[X] File '$EnvVarsFile' not found. Script cannot continue! Please make sure that the `_env.ps1` file is available at the following path: 's3://$S3BucketName/$S3BucketFolder/_env.ps1'."; 
            }
            
            # Run each script that was downloaded, excluding any prefixed with underscore
            $scripts = $(Get-ChildItem -Path (Join-Path $LocalScriptFolder '*') -File -Exclude "_*");
            log -msg "Found $($scripts.Length) scripts in the '$LocalScriptFolder' folder. Iterating & executing them now.";
            foreach ($script in $scripts) {
                log -msg "Configuration script '$($script.FullName)' located. Executing now.";
                Import-Module $script.FullName
                . $script.BaseName -Verbose -ErrorAction Stop *>&1 | ForEach-Object { log -msg "$($script.BaseName): $_" };
                log -msg "Execution of configuration script '$($script.FullName)' completed.";
            }
        }
        catch {
            log "Error" "[X] An error occurred that could not be automatically resolved: $_"
            throw $_;
        }
    }

    END {
        log -msg "$(if ($PSCommandPath) { "'$PSCommandPath'" } else { "Initialisation" }) has completed successfully."
    }
};