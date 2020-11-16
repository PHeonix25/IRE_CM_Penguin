
<#PSScriptInfo

.VERSION 1.0

.GUID ec3a03a4-ef03-4e19-8798-fb15fe16de5d

.AUTHOR pat.hermens@slalom.com

.COMPANYNAME Slalom Build

.TAGS Configuration OctopusDeploy Tentacle 

#>

<# 

.SYNOPSIS 
 Configures an OctopusDeploy Tentacle

.DESCRIPTION
 Something longwinded about what it does & how it does it.

.INPUTS
 None

.OUTPUTS
 None

.EXAMPLE 
 PS> # When using command-line parameters
 PS> Set-OctopusDeployTentacleConfiguration

.EXAMPLE 
 PS> # When using environment variables
 PS> Set-OctopusDeployTentacleConfiguration

#> 
function Set-OctopusDeployTentacleConfiguration {
    [CmdletBinding()]
    param ()
    
    BEGIN {
        Write-Verbose "=> '$PSCommandPath' has started.";
    
        # Validate environment variables
        
        # Validate/assign parameters

    }

    PROCESS {
        try {

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