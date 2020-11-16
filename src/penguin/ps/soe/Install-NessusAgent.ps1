
<#PSScriptInfo

.VERSION 1.0

.GUID c4783a8e-7d4d-48ec-9ace-440f3e956809

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
 [MANDATORY] The key with enough permissions to add this agent to the requested group
 
.PARAMETER NessusGroups
 [OPTIONAL] The name of the groups that this Nessus Agent should be subscribed to

.PARAMETER NessusServer
 [OPTIONAL] The URL of the Tenable server that hosts your environment

.INPUTS
 None

.OUTPUTS
 None

.EXAMPLE 
 PS> # When using default parameter values
 PS> Install-NessusAgent -NessusKey "long-api-key"

.EXAMPLE
 PS> # When using command-line parameters
 PS> Install-NessusAgent -NessusKey "long-api-key" -NessusGroups "AU Servers" -NessusServer "cloud.tenable.com"

#> 
function Install-NessusAgent {
    [CmdletBinding()]
    param (
        [string]$NessusKey,
        [string]$NessusGroups = "AU Servers",
        [string]$NessusServer = "cloud.tenable.com"
    )
    
    BEGIN {
        Write-Verbose "=> '$PSCommandPath' has started.";

        # Validate/assign parameters
        if (-not $NessusKey) {
            throw [System.ArgumentNullException]("NessusKey")
        }
        if (-not $NessusGroups) {
            throw [System.ArgumentNullException]($NessusGroups)
        }
        if (-not $NessusServer) {
            throw [System.ArgumentNullException]($NessusServer)
        }

        # Assign global variables
        $NessusAgentDownloadURL = "https://www.tenable.com/downloads/api/v1/public/pages/nessus-agents/downloads/11782/download?i_agree_to_tenable_license_agreement=true"
        $PublishedNessusAgentHash = "d7cac60d8b8fb3cca566ae14cc937718da7eac711b282416c661af7afe13c7a5".ToUpper()
        $DownloadedNessusAgent = "NessusAgent.msi"
        $LoggingReplacement = "***REMOVED***"

        # Download prerequisite packages
        if (Test-Path $DownloadedNessusAgent) {
            Write-Warning "Downloaded Nessus Agent located ('$(Resolve-Path $DownloadedNessusAgent)'); Skipping download!"
        } else {
            Invoke-WebRequest -Uri $NessusAgentDownloadURL -OutFile $DownloadedNessusAgent
        }

        $DownloadedNessusAgentHash = (Get-FileHash -Algorithm SHA256 -Path $DownloadedNessusAgent).Hash;
        Write-Verbose "Downloaded '$(Resolve-Path $DownloadedNessusAgent)' - HASH: $DownloadedNessusAgentHash";

        if ($DownloadedNessusAgentHash -ne $PublishedNessusAgentHash) {
            throw "Downloaded NessusAgent file hash is different from expected!`n`n" +`
                    "EXPECTED: $PublishedNessusAgentHash`n`n" +`
                    "RECEIVED: $DownloadedNessusAgentHash`n`n";
        } else {
            Write-Verbose "'$(Resolve-Path $DownloadedNessusAgent)': SHA256 Hash meets expectation."
        }
    }

    PROCESS {
        try {
            $executable = "msiexec"
            $arguments = "/i $DownloadedNessusAgent /passive /norestart /qn /L*V "".\nessus_installation.log"" NESSUS_GROUPS=""$NessusGroups"" NESSUS_SERVER=""$NessusServer"" NESSUS_KEY=""$LoggingReplacement"""
            Write-Verbose "Executing: $executable $arguments"
            $arguments = $arguments.Replace($LoggingReplacement, $NessusKey)
            Start-Process $executable -ArgumentList $arguments -Wait
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