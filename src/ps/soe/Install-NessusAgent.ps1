
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
        [Alias("G")][string]$NessusGroups,
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
        $DownloadedNessusAgent = "NessusAgent-8.2.1-x64.msi"
        $InstalledNessusExe = "C:\Program Files\Tenable\Nessus Agent\nessuscli.exe"
        $LoggingReplacement = "***REMOVED***"
        $S3Region =  "eu-west-1"
        $S3BucketName = $ENV:PenguinInfraBucketName
        $S3BucketObject = (Join-Path "soe\installers" $DownloadedNessusAgent)
        
        Write-Output "All EnvVar Keys: $(Get-ChildItem ENV: | ForEach-Object { Write-Output $_.Key })"
    }

    PROCESS {
        try {
            # Download installer package
            if (Test-Path $InstalledNessusExe) {
                Write-Output "Nessus Agent executable is already installed! Skipping download."
            } else {
                if (Test-Path $DownloadedNessusAgent) {
                    Write-Warning "Previously downloaded Nessus Agent located ('$(Resolve-Path $DownloadedNessusAgent)'); Skipping download!"
                } else {
                    # Fetch from S3?
                    if (-not $S3BucketName) {
                        throw "S3BucketName for Nessus Installer was not specified. Please populate the 'PenguinInfraBucketName' environment variable!"
                    } elseif (Get-S3Object -Region $S3Region -BucketName $S3BucketName) {
                        Read-S3Object -Region $S3Region -BucketName $S3BucketName -Key $S3BucketObject -File $DownloadedNessusAgent
                        Write-Output "'$S3BucketObject' from the '$S3BucketName' S3Bucket has been downloaded to '$(Resolve-Path $DownloadedNessusAgent)'."
                    } else {
                        throw "S3Bucket '$S3BucketName' could not be read. Please check permissions if it exists!"
                    }
                }
            }

            # Installation
            if (Test-Path $InstalledNessusExe) {
                Write-Output "Nessus Agent executable is already installed! Skipping installation."
            } else {
                $arguments = "/i $DownloadedNessusAgent /passive /norestart /qn /LAME "".\install_nessusagent.log"" NESSUS_GROUPS=""$NessusGroups"" NESSUS_KEY=""$LoggingReplacement"""
                Write-Verbose "Executing: 'msiexec $arguments'"
                $arguments = $arguments.Replace($LoggingReplacement, $NessusKey)
                Start-Process "msiexec" -ArgumentList $arguments -Wait
            }

            # Configuration: 
            # 'agent link --cloud --key=$NessusKey --groups=$NessusGroups --name=$NessusInstanceName'
            $arguments = "agent link --cloud --key=$LoggingReplacement --groups=$NessusGroups --name=$NessusInstanceName"
            Write-Verbose "Executing: '$InstalledNessusExe $arguments'"
            $arguments = $arguments.Replace($LoggingReplacement, $NessusKey)
            Start-Process $InstalledNessusExe -ArgumentList $arguments -Wait

            Write-Output "All done. Nessus Agent is installed and configured."

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