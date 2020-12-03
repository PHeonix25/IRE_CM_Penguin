<#PSScriptInfo

.VERSION 1.0

.GUID 715f9b05-cc07-4527-b268-9df1a3d1c148

.AUTHOR pat.hermens@slalom.com

.COMPANYNAME Slalom Build

.TAGS Installation Configuration Customer

#>

<# 

.SYNOPSIS 
 Runs the scripts that have been provided by the customer

.DESCRIPTION
 Runs the scripts that have been provided by the customer, 
 capturing any output in a 'customer-provided.txt' log file.

.PARAMETER ScriptLocation
 The folder that contains the customer-provided Powershell scripts

.PARAMETER EntryPoint
 The initial Powershell script to call from within that folder

.INPUTS
 None

.OUTPUTS
 None

.EXAMPLE 
 PS> Invoke-CustomerProvidedScripts

 #> 
function Invoke-CustomerProvidedScripts {
    [CmdletBinding()]
    param (
        [string]$ScriptLocation = ".\customer-provided",
        [string]$EntryPoint = "DeployWebsites.ps1"
    )
    
    BEGIN {
        Write-Verbose "=> '$PSCommandPath' has started.";
        Start-Transcript -Path "customer-provided.txt" -UseMinimalHeader
    }

    PROCESS {
        try {
            
            Set-Location $(Resolve-Path $ScriptLocation);
            & $(Resolve-Path $EntryPoint)

        }
        catch {
            Write-Error "An error occurred that could not be automatically resolved:"
            throw $_;
        }
    }

    END {
        Stop-Transcript
        Write-Verbose "=> '$PSCommandPath' has completed successfully.";
    }
};
