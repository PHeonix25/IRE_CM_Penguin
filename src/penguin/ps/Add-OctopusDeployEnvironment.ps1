
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

.PARAMETER ToolsDirectory
 Specifies path to Octo tools directory

.PARAMETER Name
 The name of the environment that you want to add to Octo

.PARAMETER OctopusServer
 The full URL to the admin interface for your OctopusDeploy Server

.PARAMETER OctopusApiKey
 An API key that we can use to administer the OctopusDeploy Server.
 Should start with API-

.INPUTS
 None

.OUTPUTS
 None

.EXAMPLE 
 PS> # When using command-line parameters
 PS> Add-OctopusDeployEnvironment -Name 'New Environment Name' -OctopusServer http://localhost:8080 -OctopusApiKey API-#######

.EXAMPLE 
 PS> # When using environment variables
 PS> Add-OctopusDeployEnvironment -Name 'New Environment Name'

#> 
function Add-OctopusDeployEnvironment {
    [CmdletBinding()]
    param 
    (
        [string]$ToolsDirectory = '.\OctopusTools.7.4.2.portable', 
        [string]$Name = 'Dev-IRE',
        [string]$OctopusServer, 
        [string]$OctopusApiKey
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
    }

    PROCESS {
        try {
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
        Write-Verbose "=> '$PSCommandPath' has completed successfully.";
    }
};