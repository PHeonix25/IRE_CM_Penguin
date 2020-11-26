
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
 
.PARAMETER OctopusTentacleInstanceName
 The name that you want this instance to have.
 [DEFAULT VALUE: Machine Host Name]

.PARAMETER OctopusTentaclePort
 The port that you want the OctopusDeploy Tentacle communication to happen on
 [DEFAULT VALUE: 10933]

.PARAMETER OctopusTentacleRootFolder
 The folder that you want Octopus Tentacle config (& application deployments) to live in
 [DEFAULT VALUE: "C:\Octopus\"]

.PARAMETER OctopusTentacleRoles
 An array of roles that this Tentacle should be registered with.
 These will be iterated over during configuration, so even if you have a single value, 
 please provide it as an array of one item.
 [DEFAULT VALUE: Array of one empty string `@("")`]

.PARAMETER OctopusTentacleEnvironment
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
 PS> Set-OctopusDeployTentacleConfiguration -OctopusServerUrl "http://localhost:8080" -OctopusServerApiKey "API-XXXXX" -OctopusServerThumbprint "123456ABCDEF" -OctopusTentacleRoles @("web-app") 

.EXAMPLE 
 PS> # When using aliases & default values
 PS> Set-OctopusDeployTentacleConfiguration -server "http://localhost:8080" -apikey "API-XXXXX" -thumb "123456ABCDEF" -roles @("web-app") 

.EXAMPLE 
 PS> # Using all parameters
 PS> Set-OctopusDeployTentacleConfiguration -OctopusServerUrl "http://localhost:8080" -OctopusServerApiKey "API-XXXXX" `
      -OctopusServerThumbprint "123456ABCDEF" -OctopusTentacleRoles @("web-app") -OctopusTentacleInstanceName "HOST1234" `
      -OctopusTentaclePort 10934 -OctopusTentacleRootFolder "C:\Octo" -OctopusTentacleEnvironment "Test"

.EXAMPLE 
 PS> # Using all parameters via their aliases
 PS> Set-OctopusDeployTentacleConfiguration -server "http://localhost:8080" -apikey "API-XXXXX" -thumb "123456ABCDEF" -roles @("web-app") -name "HOST1234" -port 10934 -folder "C:\Octo" -env "Test"

#> 
function Set-OctopusDeployTentacleConfiguration {
    [CmdletBinding()]
    param (
        [Alias("server")][string]$OctopusServerUrl,
        [Alias("apikey")][string]$OctopusServerApiKey,
        [Alias("thumb")][string]$OctopusServerThumbprint,
        [Alias("name")][string]$OctopusTentacleInstanceName,
        [Alias("port")][uint]$OctopusTentaclePort = 10933,
        [Alias("folder")][string]$OctopusTentacleRootFolder = "C:\Octopus",
        [Alias("roles")][ValidateLength(1,10)][string[]]$OctopusTentacleRoles = @(""),
        [Alias("env")][string]$OctopusTentacleEnvironment = "Dev"
    )

    BEGIN {
        Write-Verbose "=> '$PSCommandPath' has started.";
    
        # Fall-back to ENV VARS, if not provided as parameters
        if ((-not $OctopusServerUrl) -and $ENV:OctopusServerUrl) {
            $OctopusServerUrl = $ENV:OctopusServerUrl
            Write-Verbose "OctopusDeploy Server URL loaded from matching environment variable."
        }
        if ((-not $OctopusServerApiKey) -and $ENV:OctopusServerApiKey) {
            $OctopusServerApiKey = $ENV:OctopusServerApiKey
            Write-Verbose "OctopusDeploy Server API KEY loaded from matching environment variable."
        }
        if ((-not $OctopusServerThumbprint) -and $ENV:OctopusServerThumbprint) {
            $OctopusServerThumbprint = $ENV:OctopusServerThumbprint
            Write-Verbose "OctopusDeploy Server THUMBPRINT loaded from matching environment variable."
        }

        # Validate/assign parameters
        if (-not $OctopusServerUrl) {
            Write-Error "OctopusServer URL is not available. Script cannot continue."
            throw [System.ArgumentNullException] "OctopusServerUrl"
        }
        if (-not $OctopusServerApiKey) {
            Write-Error "OctopusServer API Key is not available. Script cannot continue."
            throw [System.ArgumentNullException] "OctopusServerApiKey"
        }
        if (-not $OctopusServerThumbprint) {
            Write-Error "OctopusServer Thumbprint is not available. Script cannot continue."
            throw [System.ArgumentNullException] "OctopusServerThumbprint"
        }
        if (-not $OctopusTentacleRoles) {
            Write-Error "No roles are assigned to this instance, cannot continue until roles are provided."
            throw [System.ArgumentNullException] "OctopusTentacleRoles";
        }
        if (-not $OctopusTentacleInstanceName) {
            $OctopusTentacleInstanceName = "$OctopusTentacleEnvironment--$ENV:ComputerName"
            Write-Warning "OctopusTentacleInstanceName variable not provided, defaulting to Environment-ComputerName ('$OctopusTentacleInstanceName')"
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
            $arguments = "create-instance --instance ""$OctopusTentacleInstanceName"" --config ""$OctopusTentacleRootFolder\Tentacle.config"" --console"
            Write-Verbose "Executing: '$InstalledTentacleExe $arguments'"
            Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait

            # new-certificate --if-blank
            $arguments = "new-certificate --instance ""$OctopusTentacleInstanceName"" --if-blank --console"
            Write-Verbose "Executing: '$InstalledTentacleExe $arguments'"
            Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait

            # --reset-trust
            $arguments = "configure --instance ""$OctopusTentacleInstanceName"" --reset-trust --console"
            Write-Verbose "Executing: '$InstalledTentacleExe $arguments'"
            Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait

            # --home && --app && --port
            $arguments = "configure --instance ""$OctopusTentacleInstanceName"" --home ""$OctopusTentacleRootFolder\"" --app ""$OctopusTentacleRootFolder\Applications"" --port ""$OctopusTentaclePort"" --console"
            Write-Verbose "Executing: '$InstalledTentacleExe $arguments'"
            Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait

            # --trust "YOUR_OCTOPUS_THUMBPRINT"
            $arguments = "configure --instance ""$OctopusTentacleInstanceName"" --trust ""$LoggingReplacement"" --console"
            Write-Verbose "Executing: '$InstalledTentacleExe $arguments'"
            $arguments = $arguments.Replace($LoggingReplacement, $OctopusServerThumbprint)
            Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait

            # Open firewall
            $arguments = "advfirewall firewall add rule ""name=Octopus Deploy Tentacle"" dir=in action=allow protocol=TCP localport=$OctopusTentaclePort"
            Write-Verbose "Executing: '""netsh"" $arguments'"
            Start-Process """netsh""" -ArgumentList $arguments -Wait

            # register-with --server "http://YOUR_OCTOPUS" --apiKey="API-YOUR_API_KEY" --role "XXX" --environment "YYY" --comms-style TentaclePassive --console
            foreach ($role in $OctopusTentacleRoles) { # Need to 'register' once per desired role:
                $arguments = "register-with --instance ""$OctopusTentacleInstanceName"" --server ""$OctopusServerUrl"" --apiKey ""$LoggingReplacement"" `
                    --role ""$role"" --environment ""$OctopusTentacleEnvironment"" --comms-style ""TentaclePassive"" --console"
                Write-Verbose "Executing: '$InstalledTentacleExe $arguments'"
                $arguments = $arguments.Replace($LoggingReplacement, $OctopusServerApiKey)
                Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait
            }

            # service --instance "Tentacle" --install --start --console
            $arguments = "service --instance ""$OctopusTentacleInstanceName"" --install --start --console"
            Write-Verbose "Executing: '$InstalledTentacleExe $arguments'"
            Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait

            Write-Output "[✓] All done. OctopusDeploy Tentacle is installed & configured."
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