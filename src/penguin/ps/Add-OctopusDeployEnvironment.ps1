
<#PSScriptInfo

.VERSION 1.0

.GUID fa522524-d0fc-40a4-9a95-1aa11d2b516c

.AUTHOR pat.hermens@slalom.com

.COMPANYNAME Slalom Build

.TAGS Configuration OctopusDeploy Server Environment

#>

<# 

.SYNOPSIS 
 Adds an Environment to the OctopusDeploy Server 

.DESCRIPTION
 This script will use the cross-platform/portable 'octo' tool to 
 manipulate the REST-API of the OctopusDeploy Server in order to 
 create a new Environment for OctopusDeploy Tentacles to attach to.

 Version 7.4.2 of the OctopusTools are bundled with this script, 
 but if you want to use a different (newer?) version, then you can override
 that path by specifying the $ToolsDirectory parameter

 This application also respects the normal Environment Variables 
 (that should be present on Production Octopus Deploy systems), so
 you should not need to pass the OctopusServer and OctopusApiKey values 
 when running this on Production. 
 For development/Docker purposes though, we allow you to override them

.PARAMETER Name
 [MANDATORY] The name of the environment that you want to add to Octo

.PARAMETER OctopusServer
 [MANDATORY] The full URL to the admin interface for your OctopusDeploy Server

.PARAMETER OctopusApiKey
 [MANDATORY] An API key that we can use to administer the OctopusDeploy Server.
 Should start with 'API-'

.PARAMETER CleanUp
 [DEFAULT VALUE: $true] 
 A flag used to check if we should delete the files that we download.
 

.INPUTS
 None

.OUTPUTS
 None

.EXAMPLE 
 PS> # When using command-line parameters
 PS> Add-OctopusDeployEnvironment -EnvironmentName 'New Environment Name' -OctopusServer http://localhost:8080 -OctopusApiKey API-#######

.EXAMPLE 
 PS> # When using environment variables
 PS> Add-OctopusDeployEnvironment -EnvironmentName 'New Environment Name'

#> 
function Add-OctopusDeployEnvironment {
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory)][Alias("EnvName")][string]$EnvironmentName,
        [Parameter(Mandatory)][Alias("Server")][string]$OctopusServer, 
        [Parameter(Mandatory)][Alias("ApiKey")][string]$OctopusApiKey,
        [bool]$CleanUp = $true
    )
    
    BEGIN {
        Write-Verbose "=> '$PSCommandPath' has started.";
    
        # Validate environment variables
        if ($null -eq $ENV:OCTOPUS_CLI_SERVER) {
            Write-Warning "OCTOPUS_CLI_SERVER environment variable not present"
            if (-not $OctopusServer) {
                throw "OCTOPUS_CLI_SERVER env var not present & no additional value provided";
            }
        }
        if ($null -eq $ENV:OCTOPUS_CLI_API_KEY) {
            Write-Warning "OCTOPUS_CLI_API_KEY environment variable not present"
            if (-not $OctopusApiKey) {
                throw "OCTOPUS_CLI_API_KEY env var not present & no additional value provided";
            }
        }
        
        # Validate/assign parameters
        $OctopusServer = $OctopusServer ?? $ENV:OCTOPUS_CLI_SERVER;
        if (-not ($OctopusServer)) {
            throw "OCTOPUS_CLI_SERVER value could not be located or assigned. Please provide a value via command-line arguments"
        }
        $OctopusApiKey = $OctopusApiKey ?? $ENV:OCTOPUS_CLI_API_KEY;
        if (-not ($OctopusApiKey)) {
            throw "OCTOPUS_CLI_API_KEY value could not be located or assigned. Please provide a value via command-line arguments"
        }

        # Assign global variables
        $OctopusToolsVersion = "7.4.2"
        $ToolsDownloadURL = "https://download.octopusdeploy.com/octopus-tools/$OctopusToolsVersion/OctopusTools.$OctopusToolsVersion.portable.zip"
        $PublishedToolsHash = "00815383ABD100C4BBA39E141EE996A2"
        $DownloadedToolsZip = "OctopusTools-$OctopusToolsVersion.zip"
        $ToolsDirectory = ".\OctopusTools-$OctopusToolsVersion"

        # Download pre-requisite tooling
        if (Test-Path $DownloadedToolsZip) {
            Write-Warning "Previously downloaded OctopusTools zipfile located ('$(Resolve-Path $DownloadedToolsZip)'); Skipping download!"
        } else {
            Invoke-WebRequest -Uri $ToolsDownloadURL -OutFile $DownloadedToolsZip
        }

        $DownloadedToolsHash = (Get-FileHash -Algorithm MD5 -Path $DownloadedToolsZip).Hash;
        Write-Verbose "Located '$(Resolve-Path $DownloadedToolsZip)' - HASH: $DownloadedToolsHash";

        if ($DownloadedToolsHash -ne $PublishedToolsHash) {
            throw "OctopusTools installer hash is different from expected!`n`n" +`
                    "EXPECTED: $PublishedToolsHash`n`n" +`
                    "RECEIVED: $DownloadedToolsHash`n`n";
        } else {
            Write-Verbose "'$(Resolve-Path $DownloadedToolsZip)': MD5 Hash meets expectation."
        }

        Write-Verbose "About to extract zip file ($DownloadedToolsZip) to folder ($ToolsDirectory)."
        Expand-Archive $DownloadedToolsZip -DestinationPath $ToolsDirectory;
        Write-Verbose "Files extracted successfully."
    }

    PROCESS {
        try {
            if (-not (Test-Path $ToolsDirectory\octo.dll)) {
                throw "OctopusTools not found in correct directory. Please delete downloaded files & re-run script."
            }

            $version = & dotnet $ToolsDirectory\octo.dll "version"
            Write-Host -ForegroundColor Green "Tools found! 'octo' version: $version"
            Invoke-Expression "dotnet $ToolsDirectory\octo.dll create-environment --server $OctopusServer --apiKey $OctopusApiKey --name $Name --ignoreIfExists"
        }
        catch {
            Write-Error "An error occurred that could not be automatically resolved:"
            throw $_;
        }
    }

    END {
        if ($CleanUp) {
            Write-Verbose "All done, now tidying up after ourselves..."
            Remove-Item $DownloadedToolsZip -Force -Recurse
            Remove-Item $ToolsDirectory -Force -Recurse
        }

        Write-Verbose "=> '$PSCommandPath' has completed successfully.";
    }
};