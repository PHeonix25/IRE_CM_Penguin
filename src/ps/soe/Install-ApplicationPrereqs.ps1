
<#PSScriptInfo

.VERSION 1.0

.GUID adbb138d-52b2-42b9-b8e5-b3affa172f29

.AUTHOR pat.hermens@slalom.com

.COMPANYNAME Slalom Build

.TAGS Installation Configuration Windows Server

#>

<# 

.SYNOPSIS 
 Downloads, installs, and configures Windows Server 2016 to client specifications

.DESCRIPTION
 Enables a bunch of additional Windows Features in the build, and then 
 downloads the URL Rewrite module (from S3) and installs it.

.INPUTS
 None

.OUTPUTS
 None

#> 
function Install-ApplicationPrereqs {
    [CmdletBinding()]
    param ()
    
    BEGIN {
        Write-Verbose "=> '$PSCommandPath' has started.";

        # .NET 4.8 & Core - Enable Windows Features
        $features = "Web-Server;Web-Mgmt-Tools;" + # IIS & Administration
                    "Net-Framework-Features;Net-Framework-Core;" + # .NET Framework 3.5
                    "Net-Framework-45-Features;Net-Framework-45-Core;Net-Framework-45-ASPNET;Net-WCF-Services45;" + # .NET Framework 4.x
                    "Web-App-Dev;Web-Net-Ext;Web-Net-Ext45;Web-Asp-Net;Web-Asp-Net45;Web-ISAPI-Ext;Web-ISAPI-Filter;" + # App Development Role
                    "Web-Windows-Auth;Web-Basic-Auth;" + # Windows + Basic Authentication inside IIS
                    "Web-Dyn-Compression;Web-Http-Redirect;Web-Includes;Web-Custom-Logging;Web-Http-Tracing;Web-Request-Monitor;" + # Additional IIS features
                    "Web-CGI;" # Application functionality

        # Installable dependencies
        $S3Region =  "eu-west-1"
        $S3BucketName = $ENV:PenguinInfraBucketName
        $S3BucketFolder = "soe\installers\app-prerequisites"
        $LocalScriptFolder = "C:\Configuration\installers"
    }

    PROCESS {
        try {
            # Enable each of the required Windows features
            foreach ($feature in ($features -split ';')) {
                if ($(Get-WindowsFeature $feature).InstallState -ne "Installed") {
                    Write-Warning "Windows Feature '$feature' needs to be enabled for the applications to work. Configuring now."
                    $result = Install-WindowsFeature $feature;
                    Write-Output ("Windows Feature '$feature' was installed. Exit code was $($result.ExitCode)." + 
                        $(if ($result.FeatureResult) { "`nNested Windows Features installed: $($result.FeatureResult -join ', ')." }));
                }
            }

            if (-not $S3BucketName) {
                log "Error" "[X] The S3Bucket name variable was not defined. Please check the variables you provided in your RFC!"
            } elseif (Get-S3Object -Region $S3Region -BucketName $S3BucketName) {
                Read-S3Object -Region $S3Region -BucketName $S3BucketName -KeyPrefix $S3BucketFolder -Folder $LocalScriptFolder
                log -msg "The contents of the '$S3BucketFolder' folder in the '$S3BucketName' S3Bucket have been downloaded to '$LocalScriptFolder'."
            }
            else {
                log "Error" "[X] S3Bucket at '$S3BucketName' is not accessible. Please ensure that permissions are set correctly."
            }

            $installers = $(Get-ChildItem $LocalScriptFolder);
            Write-Output "Found $($installers.Length) installers in the '$LocalScriptFolder' folder. Iterating & installing them now.";
            foreach ($installer in $installers) {
                Write-Output "Located '$installer'. Requesting install now."

                # Launch each installer
                switch ($installer.Extension) {
                    ".msi" {  
                        $arguments = "/i $installer /passive /norestart /qn"
                        Write-Verbose "Executing: 'msiexec $arguments'"
                        Start-Process "msiexec" -ArgumentList $arguments -Wait;
                    }
                    ".exe" {
                        Write-Verbose "Executing: '& $installer'"
                        & $installer;
                    }
                    default {
                        Write-Warning "Installer extension was '$($installer.Extension)' which we cannot process. Please update Install-ApplicationPrereqs.ps1 to hande this extension."
                    }
                }
            }

            Write-Output "All done. Windows features enabled & installers executed."
        }
        catch {
            Write-Error "An error occurred that could not be automatically resolved: $_"
            throw $_;
        }
    }

    END {
        Write-Verbose "=> '$PSCommandPath' has completed successfully.";
    }
};