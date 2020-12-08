
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

 .PARAMETER OctopusTentacleEnvironment
 The environment that this Tentacle should be registered to.
 [DEFAULT VALUE: "Dev"]

.PARAMETER OctopusTentacleInstanceName
 The name that you want this instance to have.
 [DEFAULT VALUE: Machine Host Name]

.PARAMETER OctopusTentaclePort
 The port that you want the OctopusDeploy Tentacle communication to happen on
 [DEFAULT VALUE: 10933]

 .PARAMETER OctopusTentacleRoles
 An array of roles that this Tentacle should be registered with.
 These will be iterated over during configuration after splitting the string by semi-colon (;)
 [DEFAULT VALUE: $null

.PARAMETER OctopusTentacleRootFolder
 The folder that you want Octopus Tentacle config (& application deployments) to live in
 [DEFAULT VALUE: "C:\Octopus\"]

.INPUTS
 None

.OUTPUTS
 None

.LINK
https://octopus.com/docs/infrastructure/deployment-targets/windows-targets/automating-tentacle-installation

.EXAMPLE 
 PS> # When using command-line parameters & default values
 PS> Set-OctopusDeployTentacleConfiguration -OctopusServerUrl "http://localhost:8080" -OctopusServerApiKey "API-XXXXX" -OctopusServerThumbprint "123456ABCDEF" -OctopusTentacleRoles "web-app" 

.EXAMPLE 
 PS> # When using aliases & default values
 PS> Set-OctopusDeployTentacleConfiguration -server "http://localhost:8080" -apikey "API-XXXXX" -thumb "123456ABCDEF" -roles "web-app"

.EXAMPLE 
 PS> # Using all parameters
 PS> Set-OctopusDeployTentacleConfiguration -OctopusServerUrl "http://localhost:8080" -OctopusServerApiKey "API-XXXXX" `
      -OctopusServerThumbprint "123456ABCDEF" -OctopusTentacleRoles "web-app" -OctopusTentacleInstanceName "HOST1234" `
      -OctopusTentaclePort 10943 -OctopusTentacleRootFolder "C:\Octo" -OctopusTentacleEnvironment "Test"

.EXAMPLE 
 PS> # Using all parameters via their aliases
 PS> Set-OctopusDeployTentacleConfiguration -server "http://localhost:8080" -apikey "API-XXXXX" -thumb "123456ABCDEF" -roles "web-app" -name "HOST1234" -port 10943 -folder "C:\Octo" -env "Test"

#> 
function Set-OctopusDeployTentacleConfiguration {
    [CmdletBinding()]
    param (
        [Alias("apikey")][string]$OctopusServerApiKey,
        [Alias("server")][string]$OctopusServerUrl,
        [Alias("thumb")] [string]$OctopusServerThumbprint,
        [Alias("env")]   [string]$OctopusTentacleEnvironment,
        [Alias("name")]  [string]$OctopusTentacleInstanceName,
        [Alias("port")]  [int]   $OctopusTentaclePort = 10943,
        [Alias("roles")] [string]$OctopusTentacleRoles,
        [Alias("folder")][string]$OctopusTentacleRootFolder = "C:\Octopus"
    )

    BEGIN {
        Write-Information "=> '$PSCommandPath' has started.";
    
        # Fall-back to ENV VARS, if available & matching parameter not passed in
        if (Get-ChildItem -Path "ENV:Octopus*") {
            if ((-not $OctopusServerApiKey) -and $ENV:OctopusServerApiKey) {
                $OctopusServerApiKey = $ENV:OctopusServerApiKey
                Write-Information "OctopusDeploy Server API KEY loaded from matching environment variable."
            }
            if ((-not $OctopusServerUrl) -and $ENV:OctopusServerUrl) {
                $OctopusServerUrl = $ENV:OctopusServerUrl
                Write-Information "OctopusDeploy Server URL loaded from matching environment variable."
            }
            if ((-not $OctopusServerThumbprint) -and $ENV:OctopusServerThumbprint) {
                $OctopusServerThumbprint = $ENV:OctopusServerThumbprint
                Write-Information "OctopusDeploy Server THUMBPRINT loaded from matching environment variable."
            }
            if ((-not $OctopusTentacleEnvironment) -and $ENV:OctopusTentacleEnvironment) {
                $OctopusTentacleEnvironment = $ENV:OctopusTentacleEnvironment
                Write-Information "OctopusDeploy Tentacle ENVIRONMENT loaded from matching environment variable."
            }
            if ((-not $OctopusTentacleInstanceName) -and $ENV:OctopusTentacleInstanceName) {
                $OctopusTentacleInstanceName = $ENV:OctopusTentacleInstanceName
                Write-Information "OctopusDeploy Tentacle INSTANCENAME loaded from matching environment variable."
            }
            if ((-not $OctopusTentaclePort) -and $ENV:OctopusTentaclePort) {
                $OctopusTentaclePort = $ENV:OctopusTentaclePort
                Write-Information "OctopusDeploy Tentacle PORT loaded from matching environment variable."
            }
            if ((-not $OctopusTentacleRoles) -and $ENV:OctopusTentacleRoles) {
                $OctopusTentacleRoles = $ENV:OctopusTentacleRoles
                Write-Information "OctopusDeploy Tentacle ROLES loaded from matching environment variable."
            }
            if ((-not $OctopusTentacleRootFolder) -and $ENV:OctopusTentacleRootFolder) {
                $OctopusTentacleRootFolder = $ENV:OctopusTentacleRootFolder
                Write-Information "OctopusDeploy Tentacle ROOTFOLDER loaded from matching environment variable."
            }
        }

        # Validate/assign parameters
        if (-not $OctopusServerApiKey) {
            Write-Error "OctopusServer API Key is not available. Script cannot continue."
            throw [System.ArgumentNullException] "OctopusServerApiKey"
        }
        if (-not $OctopusServerUrl) {
            Write-Error "OctopusServer URL is not available. Script cannot continue."
            throw [System.ArgumentNullException] "OctopusServerUrl"
        }
        if (-not $OctopusServerThumbprint) {
            Write-Error "OctopusServer Thumbprint is not available. Script cannot continue."
            throw [System.ArgumentNullException] "OctopusServerThumbprint"
        }
        if (-not $OctopusTentacleInstanceName) {
            $OctopusTentacleInstanceName = "$OctopusTentacleEnvironment--$ENV:ComputerName"
            Write-Warning "OctopusTentacleInstanceName variable not provided, defaulting to Environment-ComputerName ('$OctopusTentacleInstanceName')"
        }
        if (-not $OctopusTentacleRoles) {
            Write-Error "No roles are assigned to this instance, cannot continue until roles are provided."
            throw [System.ArgumentNullException] "OctopusTentacleRoles";
        }

        # Assign global variables
        $DownloadedTentacle = "Octopus.Tentacle.6.0.135-x64.msi"
        $InstalledTentacleExe = "C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe"
        $LoggingReplacement = "***REMOVED***"
        $S3Region =  "eu-west-1"
        $S3BucketName = $ENV:PenguinInfraBucketName
        $S3BucketObject = (Join-Path "soe\installers" $DownloadedTentacle)
    }

    PROCESS {
        try {
            if (Test-Path $InstalledTentacleExe) {
                Write-Output "OctopusDeploy Tentacle is already installed! Skipping download."
            } else {
                # Download OctopusDeploy installer packages
                if (Test-Path $DownloadedTentacle) {
                    Write-Warning "Previously downloaded Tentacle installer located ('$(Resolve-Path $DownloadedTentacle)'); Skipping download!"
                } else {
                    # Get it from S3?
                    if (-not $S3BucketName) {
                        throw "S3BucketName for OctopusDeploy Tentacle Installer was not specified. Please populate the 'PenguinInfraBucketName' environment variable!"
                    }
                    if (Get-S3Object -Region $S3Region -BucketName $S3BucketName) {
                        Read-S3Object -Region $S3Region -BucketName $S3BucketName -Key $S3BucketObject -File $DownloadedTentacle
                        Write-Output "'$S3BucketObject' from the '$S3BucketName' S3Bucket has been downloaded to '$(Resolve-Path $DownloadedTentacle)'."
                    } else {
                        throw "S3Bucket '$S3BucketName' could not be read. Please check permissions if it exists!"
                    }
                }
            }

            if (Test-Path $InstalledTentacleExe) {
                Write-Output "OctopusDeploy Tentacle already installed. Skipping installation."
            } else {
                # Install OctopusDeploy Tentacle
                $arguments = "/i ""$(Resolve-Path $DownloadedTentacle)"" ALLUSERS=1 /passive /norestart /qn /L* "".\install_tentacle.log"""
                Write-Information "Executing: 'msiexec $arguments'"
                $process = Start-Process "msiexec" -ArgumentList $arguments -Wait -PassThru -Verb runas
                if ($process.ExitCode -ne 0) { # MSIExec sucks at throwing on failure. We should check the status ourselves
                    throw "Tentacle installation process returned error code: $($process.ExitCode). Please check the logs."
                }
            }

            Write-Output "Configuring new instance/tentacle: '$OctopusTentacleInstanceName'."

            # create-instance (default configuration)
            $arguments = "create-instance --instance=""$OctopusTentacleInstanceName"" --config=""$(Join-Path $OctopusTentacleRootFolder "Tentacle.config")"" --console"
            Write-Information "Executing: '$InstalledTentacleExe $arguments'"
            Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait

            # new-certificate --if-blank
            $arguments = "new-certificate --instance=""$OctopusTentacleInstanceName"" --if-blank --console"
            Write-Information "Executing: '$InstalledTentacleExe $arguments'"
            Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait

            # configure --reset-trust
            $arguments = "configure --instance=""$OctopusTentacleInstanceName"" --reset-trust --console"
            Write-Information "Executing: '$InstalledTentacleExe $arguments'"
            Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait

            # configure --home && --app && --port && --noListen "True"
            $arguments = "configure --instance=""$OctopusTentacleInstanceName"" --home=""$OctopusTentacleRootFolder"" --app=""$(Join-Path $OctopusTentacleRootFolder "Applications")"" --port=""$OctopusTentaclePort"" --noListen=""True"" --console"
            Write-Information "Executing: '$InstalledTentacleExe $arguments'"
            Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait

            # configure --trust "YOUR_OCTOPUS_THUMBPRINT"
            $arguments = "configure --instance=""$OctopusTentacleInstanceName"" --trust=""$LoggingReplacement"" --console"
            Write-Information "Executing: '$InstalledTentacleExe $arguments'"
            $arguments = $arguments.Replace($LoggingReplacement, $OctopusServerThumbprint)
            Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait

            # polling-proxy --instance "Tentacle" --proxyEnable "False" --proxyUsername "" --proxyPassword "" --proxyHost "" --proxyPort ""
            $arguments = "polling-proxy --instance=""$OctopusTentacleInstanceName"" --proxyEnable=""False"" --proxyUsername="""" --proxyPassword="""" --proxyHost="""" --proxyPort="""" --console"
            Write-Information "Executing: '$InstalledTentacleExe $arguments'"
            Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait

            # Open firewall
            $arguments = "advfirewall firewall add rule ""name=Octopus Deploy Tentacle"" dir=in action=allow protocol=TCP localport=$OctopusTentaclePort"
            Write-Information "Executing: '""netsh"" $arguments'"
            Start-Process """netsh""" -ArgumentList $arguments -Wait

            # register-with --server "https://YOUR_OCTOPUS" --apiKey="API-YOUR_API_KEY" --role "XXX" --environment "YYY" --comms-style TentacleActive --console
            $arguments = "register-with --instance=""$OctopusTentacleInstanceName"" --server=""$OctopusServerUrl"" --apiKey=""$LoggingReplacement"" --name=""$OctopusTentacleInstanceName"" --environment=""$OctopusTentacleEnvironment"" --comms-style=""TentacleActive"" --console"
            foreach ($role in ($OctopusTentacleRoles -split ';')) { # Need to add each desired role:
                $arguments += " --role=""$role"""    
            }
            Write-Information "Executing: '$InstalledTentacleExe $arguments'"
            $arguments = $arguments.Replace($LoggingReplacement, $OctopusServerApiKey)
            Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait

            # service --instance "Tentacle" --install --stop --start --console
            $arguments = "service --instance=""$OctopusTentacleInstanceName"" --install --stop --start --console"
            Write-Information "Executing: '$InstalledTentacleExe $arguments'"
            Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait

            Write-Output "All done! OctopusDeploy Tentacle is installed & configured."
        }
        catch {
            Write-Error "An error occurred that could not be automatically resolved: $_"
            throw $_;
        }
    }

    END {
        Write-Information "=> '$PSCommandPath' has completed successfully.";
    }
};