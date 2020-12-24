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

            # Run each 'Deploy' script that was downloaded, excluding any prefixed with underscore
            $scripts = $(Get-ChildItem -Path (Join-Path $ConfigLocation 'Deploy*') -File -Exclude "_*");
            Write-Verbose "Found $($scripts.Length) 'Deploy' scripts in the '$ConfigLocation' folder. Iterating & executing them now.";
            foreach ($script in $scripts) {
                Write-Verbose "Configuration script '$($script.FullName)' located. Executing now.";
                . "$script";
                Write-Verbose "Execution of configuration script '$($script.FullName)' completed.";
            }

            # Create self-signed certificate & add it to root cert store
            $DomainName = "*.covermore.co.uk";
            New-SelfSignedCertificate -DnsName $DomainName -CertStoreLocation "cert:\LocalMachine\My"
            Write-Output "Created new self-signed certificate for DnsName '$DomainName'."
            $cert = (Get-ChildItem "cert:\LocalMachine\My" | Where-Object Subject -like "$DomainName*").Thumbprint
            Write-Output "Located certificate with thumbprint '$cert'. Moving to Root store."
            Copy-Item "cert:\LocalMachine\My\$cert" -Destination "cert:\LocalMachine\Root\" -Verbose
            Write-Output "Certificate ('$cert') has been copied to the Root store.";

            Import-Module WebAdministration;
            $hostsFilePath = "$($ENV:WinDir)\system32\Drivers\etc\hosts"
            $hostsFile = Get-Content $hostsFilePath;
            foreach ($site in $(Get-ChildItem IIS:\Sites | Where-Object Name -ne "Default Web Site")) {
                $siteName = $site.Name;

                # Add HTTPS to each site (except the 'Default Web Site')
                New-WebBinding -Name "$siteName" -IpAddress "*" -Protocol "https" -Port 443 -HostHeader "$siteName"
                Write-Output "New HTTPS binding has been added to '$siteName'."
                # For some reason the return object for 'new-webbinding' is not the same as the return object from 'get-webbinding'!?
                (Get-WebBinding -Name "$siteName" -Protocol "https" -Port 443 -HostHeader "$siteName").AddSslCertificate($cert, "Root")
                Write-Output "HTTPS binding for '$siteName' has been updated to use the self-signed certificate '$cert'.";

                # Add hostsfile entries for each site (to enable local access without DNS resolution)
                $header = "# Cover-More local websites:"
                if ($hostsFile -notcontains $header)  {
                    Add-Content -Path $hostsFilePath -Encoding "utf8" -Value "`n$header ";
                }
                $escapedSiteName = [Regex]::Escape($siteName)
                $hostEntry = "127.0.0.1`t$siteName";
                if ($hostsFile -match ".*\s+$escapedSiteName.*")  {
                    Write-Warning "Not able to add '$hostEntry' to hostfile. Entry already exists."
                } else {
                    Write-Output "Adding '$hostEntry' to hostsfile..."
                    Add-Content -Path $hostsFilePath -Encoding "utf8" -Value $hostEntry;
                    Write-Host "'$hostEntry' has been added to the hostsfile."
                }
            }

            # Add Windows Auth & disable Anonymous access for *-crm.covermore.co.uk
            foreach ($site in $(Get-ChildItem IIS:\Sites | Where-Object Name -like "*-crm.covermore.co.uk")) {
                $siteName = $site.Name;
                Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/anonymousAuthentication" -Name "Enabled" -Value "False" -PSPath "IIS:\" -Location "$siteName"
                Write-Output "Disabled anonymous authentication for '$siteName'."
                Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/windowsAuthentication" -Name "Enabled" -Value "True" -PSPath "IIS:\" -Location "$siteName"
                Write-Output "Enabled Windows authentication for '$siteName'."
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
