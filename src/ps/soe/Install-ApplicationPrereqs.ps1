
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
                    "Web-Windows-Auth" # Windows Authentication inside IIS

        # ARR 3.0 + Redirect
        $OfflineInstaller = "rewrite_amd64_en-US.msi"
        $S3Region =  "eu-west-1"
        $S3BucketName = $ENV:PenguinInfraBucketName
        $S3BucketObject = (Join-Path "soe\installers" $OfflineInstaller)
    }

    PROCESS {
        try {
            # Enable each of the required Windows features
            foreach ($feature in ($features -split ';')) {
                if ($(Get-WindowsFeature $feature).InstallState -ne "Installed") {
                    Write-Warning "Windows Feature '$feature' needs to be enabled for the applications to work. Configuring now."
                    Install-WindowsFeature $feature;
                }
            }

            # Download installer package
            if (Test-Path $OfflineInstaller) {
                Write-Warning "Previously downloaded offline installer of the UrlRewrite Module located ('$(Resolve-Path $OfflineInstaller)'); Skipping download!"
            } else {
                # Fetch from S3?
                if (-not $S3BucketName) {
                    throw "S3BucketName for RewriteModule installer was not specified. Please populate the 'PenguinInfraBucketName' environment variable!"
                } elseif (Get-S3Object -Region $S3Region -BucketName $S3BucketName) {
                    Read-S3Object -Region $S3Region -BucketName $S3BucketName -Key $S3BucketObject -File $OfflineInstaller
                    Write-Output "'$S3BucketObject' from the '$S3BucketName' S3Bucket has been downloaded to '$(Resolve-Path $OfflineInstaller)'."
                } else {
                    throw "S3Bucket '$S3BucketName' could not be read. Please check permissions if it exists!"
                }
            }

            # Installation of Rewrite Module
            $arguments = "/i $OfflineInstaller /passive /norestart /qn /LAME "".\install_rewritemodule.log"""
            Write-Verbose "Executing: 'msiexec $arguments'"
            Start-Process "msiexec" -ArgumentList $arguments -Wait


            Write-Output "All done. Windows features enabled & URL Rewrite module is installed."
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