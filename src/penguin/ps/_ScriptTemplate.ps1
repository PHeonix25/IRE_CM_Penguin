
<#PSScriptInfo

.VERSION 1.0

.GUID c4783a8e-7d4d-48ec-9ace-440f3e956809

.AUTHOR pat.hermens@slalom.com

.COMPANYNAME Slalom Build

.TAGS Space Separated Values

#>

<# 

.SYNOPSIS 
 Does something

.DESCRIPTION
 Something longwinded about what it does & how it does it.

.INPUTS
 None

.OUTPUTS
 None

.EXAMPLE 
 PS> # When using command-line parameters
 PS> _ScriptTemplate

.EXAMPLE 
 PS> # When using environment variables
 PS> _ScriptTemplate

#> 
function Verb-ScriptTemplate {
    [CmdletBinding()]
    param ()
    
    BEGIN {
        Write-Verbose "=> '$PSCommandPath' has started.";
    
        # Validate environment variables
        
        # Validate/assign parameters

    }

    PROCESS {
        try {

            # Do something

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