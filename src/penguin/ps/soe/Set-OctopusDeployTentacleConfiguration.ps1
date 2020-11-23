
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
 This script downloads the latest x64 Windows OctopusDeploy Tentacle
 It then installs, and configures it based off the parameters & default
 configuration values.

.PARAMETER OctopusServerUrl
 [MANDATORY] [Alias: server]
 The full URL (including protocol & port) for your OctopusServer instance
 
.PARAMETER OctopusServerApiKey
 [MANDATORY] [Alias: apikey]
 The API key that has been obtained from the OctopusDeploy Server
 
.PARAMETER OctopusServerThumbprint
 [MANDATORY] [Alias: thumb]
 The thumbprint for your OctopusServer (so that the Tentacle knows to trust it)
 
.PARAMETER TentacleInstanceName
 The name that you want this instance to have.
 [DEFAULT VALUE: Machine Host Name]

.PARAMETER TentaclePort
 The port that you want the OctopusDeploy Tentacle communication to happen on
 [DEFAULT VALUE: 10933]

.PARAMETER OctopusRootFolder
 The folder that you want Octopus Tentacle config (& application deployments) to live in
 [DEFAULT VALUE: "C:\Octopus\"]

.PARAMETER TentacleRoles
 An array of roles that this Tentacle should be registered with.
 These will be iterated over during configuration, so even if you have a single value, 
 please provide it as an array of one item.
 [DEFAULT VALUE: Array of one empty string `@("")`]

.PARAMETER TentacleEnvironment
 The environment that this Tentacle should be registered to.
 [DEFAULT VALUE: "Dev"]

.INPUTS
 None

.OUTPUTS
 None

.LINK
https://octopus.com/docs/infrastructure/deployment-targets/windows-targets/automating-tentacle-installation

.EXAMPLE 
 PS> # When using command-line parameters & default values
 PS> Set-OctopusDeployTentacleConfiguration -OctopusServerUrl "http://localhost:8080" -OctopusServerApiKey "API-XXXXX" -OctopusServerThumbprint "123456ABCDEF" -TentacleRoles @("web-app") 

.EXAMPLE 
 PS> # When using aliases & default values
 PS> Set-OctopusDeployTentacleConfiguration -server "http://localhost:8080" -apikey "API-XXXXX" -thumb "123456ABCDEF" -roles @("web-app") 

.EXAMPLE 
 PS> # Using all parameters
 PS> Set-OctopusDeployTentacleConfiguration -OctopusServerUrl "http://localhost:8080" -OctopusServerApiKey "API-XXXXX" `
      -OctopusServerThumbprint "123456ABCDEF" -TentacleRoles @("web-app") -TentacleInstanceName "HOST1234" `
      -TentaclePort 10934 -OctopusRootFolder "C:\Octo" -TentacleEnvironment "Test"

.EXAMPLE 
 PS> # Using all parameters via their aliases
 PS> Set-OctopusDeployTentacleConfiguration -server "http://localhost:8080" -apikey "API-XXXXX" -thumb "123456ABCDEF" -roles @("web-app") -name "HOST1234" -port 10934 -folder "C:\Octo" -env "Test"

#> 
function Set-OctopusDeployTentacleConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][ValidateNotNull()][Alias("server")][string]$OctopusServerUrl,
        [Parameter(Mandatory)][ValidateNotNull()][Alias("apikey")][string]$OctopusServerApiKey,
        [Parameter(Mandatory)][ValidateNotNull()][Alias("thumb")][string]$OctopusServerThumbprint, #"98D36D7A06413DDB520F80F8BB42D1C1B877B21A"#
        [Alias("name")][string]$TentacleInstanceName,
        [Alias("port")][uint]$TentaclePort = 10933,
        [Alias("folder")][string]$OctopusRootFolder = "C:\Octopus",
        [Alias("roles")][ValidateLength(1,10)][string[]]$TentacleRoles = @(""),
        [Alias("env")][string]$TentacleEnvironment = "Dev"
    )

    BEGIN {
        Write-Verbose "=> '$PSCommandPath' has started.";
    
        # Validate/assign parameters
        if (-not $TentacleInstanceName) {
            Write-Warning "TentacleInstanceName variable not provided, defaulting to ComputerName"
            $TentacleInstanceName = $ENV:COMPUTERNAME ?? [Environment]::MachineName ?? [System.Net.Dns]::GetHostName()
        }
        if (-not $TentacleRoles) {
            Write-Error "No roles are assigned to this instance, cannot continue until roles are provided."
            throw [System.ArgumentNullException]("TentacleRoles");
        }

        # Assign global variables
        $TentacleDownloadURL = "https://octopus.com/downloads/latest/WindowsX64/OctopusTentacle"
        $PublishedTentacleHash = "aee1e36b7fc11678ee76a8b07f807d0c".ToUpper()
        $DownloadedTentacle = "Octopus.Tentacle.msi"
        $InstalledTentacleExe = "C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe"
        $LoggingReplacement = "***REMOVED***"

        # Download prerequisite packages
        if (Test-Path $DownloadedTentacle) {
            Write-Warning "Previously downloaded Tentacle installer located ('$(Resolve-Path $DownloadedTentacle)'); Skipping download!"
        } else {
            Invoke-WebRequest -Uri $TentacleDownloadURL -OutFile $DownloadedTentacle
        }

        $DownloadedTentacleHash = (Get-FileHash -Algorithm MD5 -Path $DownloadedTentacle).Hash;
        Write-Verbose "Located '$(Resolve-Path $DownloadedTentacle)' - HASH: $DownloadedTentacleHash";

        if ($DownloadedTentacleHash -ne $PublishedTentacleHash) {
            throw "Tentacle installer hash is different from expected!`n`n" +`
                    "EXPECTED: $PublishedTentacleHash`n`n" +`
                    "RECEIVED: $DownloadedTentacleHash`n`n";
        } else {
            Write-Verbose "'$(Resolve-Path $DownloadedTentacle)': MD5 Hash meets expectation."
        }

    }

    PROCESS {
        try {

            if (Test-Path $InstalledTentacleExe) {
                Write-Information "OctopusDeploy Tentacle already installed. Skipping installation."
            } else {
                # Install OctopusDeploy Tentacle
                $arguments = "/i ""$(Resolve-Path $DownloadedTentacle)"" ALLUSERS=1 /passive /norestart /qn /LAME "".\install_tentacle.log"""
                Write-Verbose "Executing: 'msiexec $arguments'"
                $process = Start-Process "msiexec" -ArgumentList $arguments -Wait -PassThru -Verb runas
                if ($process.ExitCode -ne 0) { # MSIExec sucks at throwing on failure. We should check the status ourselves
                    throw "Tentacle installation process returned error code: $($process.ExitCode). Please check the logs."
                }
            }

            # create-instance (default configuration)
            $arguments = "create-instance --instance ""$TentacleInstanceName"" --config ""$OctopusRootFolder\Tentacle.config"" --console"
            Write-Verbose "Executing: '$InstalledTentacleExe $arguments'"
            Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait

            # new-certificate --if-blank
            $arguments = "new-certificate --instance ""$TentacleInstanceName"" --if-blank --console"
            Write-Verbose "Executing: '$InstalledTentacleExe $arguments'"
            Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait

            # --reset-trust
            $arguments = "configure --instance ""$TentacleInstanceName"" --reset-trust --console"
            Write-Verbose "Executing: '$InstalledTentacleExe $arguments'"
            Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait

            # --home && --app && --port
            $arguments = "configure --instance ""$TentacleInstanceName"" --home ""$OctopusRootFolder\"" --app ""$OctopusRootFolder\Applications"" --port ""$TentaclePort"" --console"
            Write-Verbose "Executing: '$InstalledTentacleExe $arguments'"
            Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait

            # --trust "YOUR_OCTOPUS_THUMBPRINT"
            $arguments = "configure --instance ""$TentacleInstanceName"" --trust ""$LoggingReplacement"" --console"
            Write-Verbose "Executing: '$InstalledTentacleExe $arguments'"
            $arguments = $arguments.Replace($LoggingReplacement, $OctopusServerThumbprint)
            Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait

            # Open firewall
            $arguments = "advfirewall firewall add rule ""name=Octopus Deploy Tentacle"" dir=in action=allow protocol=TCP localport=$TentaclePort"
            Write-Verbose "Executing: '""netsh"" $arguments'"
            Start-Process """netsh""" -ArgumentList $arguments -Wait

            # register-with --server "http://YOUR_OCTOPUS" --apiKey="API-YOUR_API_KEY" --role "XXX" --environment "YYY" --comms-style TentaclePassive --console
            foreach ($role in $TentacleRoles) { # Need to 'register' once per desired role:
                $arguments = "register-with --instance ""$TentacleInstanceName"" --server ""$OctopusServerUrl"" --apiKey=""$LoggingReplacement"" --role ""$role"" --environment ""$TentacleEnvironment"" --comms-style TentaclePassive --console"
                Write-Verbose "Executing: '$InstalledTentacleExe $arguments'"
                $arguments = $arguments.Replace($LoggingReplacement, $OctopusServerApiKey)
                Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait
            }

            # service --instance "Tentacle" --install --start --console
            $arguments = "service --instance ""$TentacleInstanceName"" --install --start --console"
            Write-Verbose "Executing: '$InstalledTentacleExe $arguments'"
            Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait

            Write-Host -ForegroundColor Green "[✔] All done. OctopusDeploy Tentacle is installed & configured."
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