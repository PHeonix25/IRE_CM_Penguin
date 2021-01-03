
<#PSScriptInfo

.VERSION 1.0

.GUID 1c0d6e86-ce11-4a96-a8db-7ed354d8ef4f

.AUTHOR pat.hermens@slalom.com

.COMPANYNAME Slalom Build

.TAGS IIS Configuration

#>

<# 

.SYNOPSIS 
 Reconfigure IIS according to client needs

.DESCRIPTION
 This script updates the IIS configuration for all deployed sites, 
 modifying authentication methods, and adding bindings and
 host-file entries for each local site.

.INPUTS
 None

.OUTPUTS
 None

.EXAMPLE 
 PS> Update-WebsiteConfiguration

#> 
function Update-WebsiteConfiguration {
    [CmdletBinding()]
    param ()
    
    BEGIN {
        Write-Verbose "=> '$PSCommandPath' has started.";

        Import-Module WebAdministration;
    }

    PROCESS {
        try {

            # Create self-signed certificate & add it to root cert store
            $DomainName = "*.covermore.co.uk";
            New-SelfSignedCertificate -DnsName $DomainName -CertStoreLocation "cert:\LocalMachine\My"
            Write-Output "Created new self-signed certificate for DnsName '$DomainName'."
            $cert = (Get-ChildItem "cert:\LocalMachine\My" | Where-Object Subject -like "$DomainName*").Thumbprint
            Write-Output "Located certificate with thumbprint '$cert'. Moving to Root store."
            Move-Item "cert:\LocalMachine\My\$cert" -Destination "cert:\LocalMachine\Root\"
            Write-Output "Certificate ('$cert') has been moved to the Root store.";


            $hostsFilePath = "$($ENV:WinDir)\system32\Drivers\etc\hosts"
            $hostsFile = Get-Content $hostsFilePath;

            # Loop through every configured site, except the "Default Web Site"
            foreach ($site in $(Get-ChildItem IIS:\Sites | Where-Object Name -ne "Default Web Site")) {
                $siteName = $site.Name;

                # Add HTTPS to each site
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
                    Write-Warning "Not able to add '$hostEntry' to hostsfile. Entry already exists."
                } else {
                    Write-Output "Adding '$hostEntry' to hostsfile..."
                    Add-Content -Path $hostsFilePath -Encoding "utf8" -Value $hostEntry;
                    Write-Host "Success! '$hostEntry' has been added to the hostsfile."
                }
            }

            # Add Windows Auth & disable Anonymous Auth for *-login.covermore.co.uk
            foreach ($loginSite in $(Get-ChildItem IIS:\Sites | Where-Object Name -like "*-login.covermore.co.uk")) {
                Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/anonymousAuthentication" -Name "Enabled" -Value "False" -PSPath "IIS:\" -Location "$($loginSite.Name)"
                Write-Output "Disabled Anonymous Authentication for '$($loginSite.Name)'."
                Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/windowsAuthentication" -Name "Enabled" -Value "True" -PSPath "IIS:\" -Location "$($loginSite.Name)"
                Write-Output "Enabled Windows Authentication for '$($loginSite.Name)'."
            }
            
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
