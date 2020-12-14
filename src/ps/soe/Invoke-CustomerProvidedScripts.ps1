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
        [string]$ConfigLocation = "C:\Configuration\customer-provided"
    )
    
    BEGIN {
        Write-Verbose "=> '$PSCommandPath' has started."
        Write-Verbose "Parameter values: ConfigLocation='$ConfigLocation'.";
        
        $ErrorActionPreference = "Continue"; # This pains me, but the client scripts are designed to use Errors as logic branches
        
        Start-Transcript -Path $(Join-Path $ConfigLocation "customer-provided.txt")
    }

    PROCESS {
        try {
            # Cover-More's deployment scripts uses handle.exe (???) 
            # Let's move it to the System folder so that these deployments can find it.
            $execName = "handle.exe"
            $handle = (Join-Path $ConfigLocation $execName)
            $dest = [Environment]::GetFolderPath("System");

            if (Test-Path $handle) {
                Write-Verbose "$execName located at '$handle'. Moving to '$dest' now."
                Copy-Item $handle $dest -Verbose
                if (Test-Path (Join-Path $dest $execName)) {
                    Write-Output "$execName has been moved to '$(Join-Path $dest $execName)'."
                }
            } else {
                Write-Warning "$execName was not located at '$handle'. Please double-check the path and try again."
            }

            # Run each script that was downloaded, excluding any prefixed with underscore
            $scripts = $(Get-ChildItem -Path (Join-Path $ConfigLocation 'Deploy*') -File -Exclude "_*");
            Write-Verbose "Found $($scripts.Length) 'Deploy' scripts in the '$ConfigLocation' folder. Iterating & executing them now.";
            foreach ($script in $scripts) {
                Write-Verbose "Configuration script '$($script.FullName)' located. Executing now.";
                . "$($script.BaseName)";
                Write-Verbose "Execution of configuration script '$($script.FullName)' completed.";
            }

        }
        catch {
            Write-Error "An error occurred that could not be automatically resolved: $_"
            throw $_;
        }
        finally {
            Stop-Transcript;
        }
    }

    END {
        Write-Verbose "=> '$PSCommandPath' has completed successfully.";
        $ErrorActionPreference = "Stop";
    }
};
