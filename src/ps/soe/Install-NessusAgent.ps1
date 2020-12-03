
<#PSScriptInfo

.VERSION 1.0

.GUID 8c32d3e2-ac85-4d4b-afd4-9fbc97316419

.AUTHOR pat.hermens@slalom.com

.COMPANYNAME Slalom Build

.TAGS Installation Configuration Tenable Nessus Agent 

#>

<# 

.SYNOPSIS 
 Downloads, installs, and configures a Tenable Nessus Agent

.DESCRIPTION
 Downloads the latest Nessus Agent (8.2.0), compares the SHA256 hash (to ensure integrity), 
 then executes it in the background (via 'msiexec /i /qn') to install & configure the agent.

.PARAMETER NessusKey
 The key with enough permissions to add this agent to the requested group
 
.PARAMETER NessusGroups
 The name of the groups that this Nessus Agent should be subscribed to

.PARAMETER NessusInstanceName
 The identifier that you want to use for this instance in Tenable Cloud

.INPUTS
 None

.OUTPUTS
 None

.EXAMPLE 
 PS> # When using default parameter values
 PS> Install-NessusAgent -NessusKey "long-api-key"

.EXAMPLE
 PS> # When using command-line parameters
 PS> Install-NessusAgent -NessusKey "long-api-key" -NessusGroups "AU Servers" -NessusInstanceName "TestInstance"

 .EXAMPLE
 PS> # When using alias'
 PS> Install-NessusAgent -NessusKey "long-api-key" -G "AU Servers" -N "TestInstance" 

#> 
function Install-NessusAgent {
    [CmdletBinding()]
    param (
        [Alias("K")][string]$NessusKey,
        [Alias("G")][string]$NessusGroups = "AU Servers",
        [Alias("N")][string]$NessusInstanceName
    )
    
    BEGIN {
        Write-Verbose "=> '$PSCommandPath' has started.";

        # Fall back to ENV VARs if available 
        if (Get-ChildItem -Path "ENV:Nessus*") {
            if ((-not $NessusKey) -and $ENV:NessusKey) {
                $NessusKey = $ENV:NessusKey
                Write-Verbose "Nessus Key loaded from matching environment variable."
            }
            if ((-not $NessusGroups) -and $ENV:NessusGroups) {
                $NessusGroups = $ENV:NessusGroups
                Write-Verbose "Nessus Groups loaded from matching environment variable."
            }
            if ((-not $NessusInstanceName) -and $ENV:NessusInstanceName) {
                $NessusInstanceName = $ENV:NessusInstanceName
                Write-Verbose "Nessus InstanceName loaded from matching environment variable."
            }
        }

        # Validate/assign parameters
        if (-not $NessusKey) {
            throw [System.ArgumentNullException] "NessusKey"
        }
        if (-not $NessusGroups) {
            throw [System.ArgumentNullException] "NessusGroups"
        }
        if (-not $NessusInstanceName) {
            throw [System.ArgumentNullException] "NessusInstanceName"
        }

        # Assign global variables
        $DownloadedNessusAgent = "NessusAgent.msi"
        $InstalledNessusExe = "C:\Program Files\Tenable\Nessus Agent\nessuscli.exe"
        $LoggingReplacement = "***REMOVED***"
        $S3BucketName = $ENV:PenguinInfraBucketName
        $S3BucketFolder = "installers"

        # Download prerequisite packages
        if (Test-Path $InstalledNessusExe) {
            Write-Information "Nessus Agent executable is already installed! Skipping download."
        } else {
            if (Test-Path $DownloadedNessusAgent) {
                Write-Warning "Previously downloaded Nessus Agent located ('$(Resolve-Path $DownloadedNessusAgent)'); Skipping download!"
            } else {
                # Fetch from S3?
                if (-not $S3BucketName) {
                    throw "S3BucketName for Nessus Installer was not specified. Please populate the 'PenguinInfraBucketName' environment variable!"
                }
                if (Get-S3Object -BucketName $S3BucketName) {
                    Read-S3Object -BucketName $S3BucketName -KeyPrefix $S3BucketFolder -File $DownloadedInstaller
                    log -msg "The contents of the '$S3BucketFolder' folder in the '$S3BucketName' S3Bucket have been downloaded to '$(Resolve-Path $DownloadedInstaller)'."
                } else {
                    throw "S3Bucket '$S3BucketName' could not be read. Please check permissions if it exists!"
                }
            }
        }
    }

    PROCESS {
        try {

            # Installation
            if (Test-Path $InstalledNessusExe) {
                Write-Information "Nessus Agent executable is already installed! Skipping installation."
            } else {
                $arguments = "/i $DownloadedNessusAgent /passive /norestart /qn /LAME "".\install_nessusagent.log"" NESSUS_GROUPS=""$NessusGroups"" NESSUS_KEY=""$LoggingReplacement"""
                Write-Verbose "Executing: 'msiexec $arguments'"
                $arguments = $arguments.Replace($LoggingReplacement, $NessusKey)
                Start-Process "msiexec" -ArgumentList $arguments -Wait
            }

            # Configuration: 
            # 'agent link --cloud --key=$NessusKey --groups=$NessusGroups --name=$NessusInstanceName'
            $arguments = "agent link --cloud --key=$NessusKey --groups=$NessusGroups --name=$NessusInstanceName'"
            Write-Verbose "Executing: '$InstalledNessusExe $arguments'"
            Start-Process $InstalledNessusExe -ArgumentList $arguments -Wait

            Write-Output "All done. Nessus Agent is installed and configured."

        }
        catch {
            Write-Error "An error occurred that could not be automatically resolved:"
            throw $_;
        }
    }

    END {
        Write-Verbose "=> '$PSCommandPath' has completed successfully.";
    }
};