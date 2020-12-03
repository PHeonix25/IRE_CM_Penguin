
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
        [Alias("env")]   [string]$OctopusTentacleEnvironment = "Dev",
        [Alias("name")]  [string]$OctopusTentacleInstanceName,
        [Alias("port")]  [int]   $OctopusTentaclePort = 10943,
        [Alias("roles")] [string]$OctopusTentacleRoles,
        [Alias("folder")][string]$OctopusTentacleRootFolder = "C:\Octopus"
    )

    BEGIN {
        Write-Verbose "=> '$PSCommandPath' has started.";
    
        # Fall-back to ENV VARS, if available & matching parameter not passed in
        if (Get-ChildItem -Path "ENV:Octo*") {
            if ((-not $OctopusServerApiKey) -and $ENV:OctopusServerApiKey) {
                $OctopusServerApiKey = $ENV:OctopusServerApiKey
                Write-Verbose "OctopusDeploy Server API KEY loaded from matching environment variable."
            }
            if ((-not $OctopusServerUrl) -and $ENV:OctopusServerUrl) {
                $OctopusServerUrl = $ENV:OctopusServerUrl
                Write-Verbose "OctopusDeploy Server URL loaded from matching environment variable."
            }
            if ((-not $OctopusServerThumbprint) -and $ENV:OctopusServerThumbprint) {
                $OctopusServerThumbprint = $ENV:OctopusServerThumbprint
                Write-Verbose "OctopusDeploy Server THUMBPRINT loaded from matching environment variable."
            }
            if ((-not $OctopusTentacleEnvironment) -and $ENV:OctopusTentacleEnvironment) {
                $OctopusTentacleEnvironment = $ENV:OctopusTentacleEnvironment
                Write-Verbose "OctopusDeploy Tentacle ENVIRONMENT loaded from matching environment variable."
            }
            if ((-not $OctopusTentacleInstanceName) -and $ENV:OctopusTentacleInstanceName) {
                $OctopusTentacleInstanceName = $ENV:OctopusTentacleInstanceName
                Write-Verbose "OctopusDeploy Tentacle INSTANCENAME loaded from matching environment variable."
            }
            if ((-not $OctopusTentaclePort) -and $ENV:OctopusTentaclePort) {
                $OctopusTentaclePort = $ENV:OctopusTentaclePort
                Write-Verbose "OctopusDeploy Tentacle PORT loaded from matching environment variable."
            }
            if ((-not $OctopusTentacleRoles) -and $ENV:OctopusTentacleRoles) {
                $OctopusTentacleRoles = $ENV:OctopusTentacleRoles
                Write-Verbose "OctopusDeploy Tentacle ROLES loaded from matching environment variable."
            }
            if ((-not $OctopusTentacleRootFolder) -and $ENV:OctopusTentacleRootFolder) {
                $OctopusTentacleRootFolder = $ENV:OctopusTentacleRootFolder
                Write-Verbose "OctopusDeploy Tentacle ROOTFOLDER loaded from matching environment variable."
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
        $DownloadedTentacle = "Octopus.Tentacle.msi"
        $InstalledTentacleExe = "C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe"
        $LoggingReplacement = "***REMOVED***"

        # Download prerequisite packages
        if (Test-Path $InstalledTentacleExe) {
            Write-Information "OctopusDeploy Tentacle is already installed! Skipping download."
        } else {
            if (Test-Path $DownloadedTentacle) {
                Write-Warning "Previously downloaded Tentacle installer located ('$(Resolve-Path $DownloadedTentacle)'); Skipping download!"
            } else {
                # Get it from S3?
                $S3BucketName = $ENV:PenguinInfraBucketName
                if (-not $S3BucketName) {
                    throw "S3BucketName for OctopusDeploy Tentacle Installer was not specified. Please populate the 'PenguinInfraBucketName' environment variable!"
                }
                if (Get-S3Object -BucketName $S3BucketName) {
                    $S3BucketFolder = "installers"
                    Read-S3Object -BucketName $S3BucketName -KeyPrefix $S3BucketFolder -File $DownloadedTentacle
                    log -msg "The contents of the '$S3BucketFolder' folder in the '$S3BucketName' S3Bucket have been downloaded to '$(Resolve-Path $DownloadedTentacle)'."
                } else {
                    throw "S3Bucket '$S3BucketName' could not be read. Please check permissions if it exists!"
                }
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

    }

    PROCESS {
        try {

            if (Test-Path $InstalledTentacleExe) {
                Write-Information "OctopusDeploy Tentacle already installed. Skipping installation."
            } else {
                # Install OctopusDeploy Tentacle
                $arguments = "/i ""$(Resolve-Path $DownloadedTentacle)"" ALLUSERS=1 /passive /norestart /qn /L* "".\install_tentacle.log"""
                Write-Verbose "Executing: 'msiexec $arguments'"
                $process = Start-Process "msiexec" -ArgumentList $arguments -Wait -PassThru -Verb runas
                if ($process.ExitCode -ne 0) { # MSIExec sucks at throwing on failure. We should check the status ourselves
                    throw "Tentacle installation process returned error code: $($process.ExitCode). Please check the logs."
                }
            }

            ###- SAMPLE SCRIPT -###
            # "C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe" create-instance --instance "Tentacle" --config "C:\Octopus\Tentacle.config"
            # "C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe" new-certificate --instance "Tentacle" --if-blank
            # "C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe" configure --instance "Tentacle" --reset-trust
            # "C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe" configure --instance "Tentacle" --app "C:\Octopus\Applications" --port "10933" --noListen "True"
            # "C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe" polling-proxy --instance "Tentacle" --proxyEnable "False" --proxyUsername "" --proxyPassword "" --proxyHost "" --proxyPort ""
            # "C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe" register-with --instance "Tentacle" --server "https://octopus.covermore.com" --name "CM-PENGUIN-IRE-DEV--i-069d59f4ab441fc25" --comms-style "TentacleActive" --server-comms-port "10943" --apiKey "API-IUJNQ7F0NMUKLQUHSKWXZCXWVO" --space "Default" --environment "Dev1" --role "Content Server UK" --role "Login Server UK" --role "Network Drive Server UK" --role "Payment Gateway UK" --role "Penguin Jobs Trooper UK" --role "Web Server External UK" --role "Web Server Internal UK" --role "WIBS Server UK" --role "Windows Patch Target UK" --role "UK Compatibility PARTIAL" --policy "Default Machine Policy"
            # "C:\Program Files\Octopus Deploy\Tentacle\Tentacle.exe" service --instance "Tentacle" --install --stop --start
            #######################

            # create-instance (default configuration)
            $arguments = "create-instance --instance ""$OctopusTentacleInstanceName"" --config ""$(Join-Path $OctopusTentacleRootFolder "Tentacle.config")"" --console"
            Write-Verbose "Executing: '$InstalledTentacleExe $arguments'"
            Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait

            # new-certificate --if-blank
            $arguments = "new-certificate --instance ""$OctopusTentacleInstanceName"" --if-blank --console"
            Write-Verbose "Executing: '$InstalledTentacleExe $arguments'"
            Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait

            # configure --reset-trust
            $arguments = "configure --instance ""$OctopusTentacleInstanceName"" --reset-trust --console"
            Write-Verbose "Executing: '$InstalledTentacleExe $arguments'"
            Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait

            # configure --home && --app && --port && --noListen "True"
            $arguments = "configure --instance ""$OctopusTentacleInstanceName"" --home ""$OctopusTentacleRootFolder"" --app ""$(Join-Path $OctopusTentacleRootFolder "Applications")"" --port ""$OctopusTentaclePort"" --noListen ""True"" --console"
            Write-Verbose "Executing: '$InstalledTentacleExe $arguments'"
            Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait

            # configure --trust "YOUR_OCTOPUS_THUMBPRINT"
            $arguments = "configure --instance ""$OctopusTentacleInstanceName"" --trust ""$LoggingReplacement"" --console"
            Write-Verbose "Executing: '$InstalledTentacleExe $arguments'"
            $arguments = $arguments.Replace($LoggingReplacement, $OctopusServerThumbprint)
            Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait

            # polling-proxy --instance "Tentacle" --proxyEnable "False" --proxyUsername "" --proxyPassword "" --proxyHost "" --proxyPort ""
            $arguments = "polling-proxy --instance ""$OctopusTentacleInstanceName"" --proxyEnable ""False"" --proxyUsername "" --proxyPassword "" --proxyHost "" --proxyPort "" --console"
            Write-Verbose "Executing: '$InstalledTentacleExe $arguments'"
            Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait

            # Open firewall
            $arguments = "advfirewall firewall add rule ""name=Octopus Deploy Tentacle"" dir=in action=allow protocol=TCP localport=$OctopusTentaclePort"
            Write-Verbose "Executing: '""netsh"" $arguments'"
            Start-Process """netsh""" -ArgumentList $arguments -Wait

            # register-with --server "https://YOUR_OCTOPUS" --apiKey="API-YOUR_API_KEY" --role "XXX" --environment "YYY" --comms-style TentacleActive --console
            $arguments = "register-with --instance ""$OctopusTentacleInstanceName"" --server ""$OctopusServerUrl"" --apiKey ""$LoggingReplacement"" --environment ""$OctopusTentacleEnvironment"" --comms-style ""TentacleActive"" --console"
            foreach ($role in ($OctopusTentacleRoles -split ';')) { # Need to add each desired role:
                $arguments += " --role ""$role"""    
            }
            Write-Verbose "Executing: '$InstalledTentacleExe $arguments'"
            $arguments = $arguments.Replace($LoggingReplacement, $OctopusServerApiKey)
            Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait

            # service --instance "Tentacle" --install --stop --start --console
            $arguments = "service --instance ""$OctopusTentacleInstanceName"" --install --stop --start --console"
            Write-Verbose "Executing: '$InstalledTentacleExe $arguments'"
            Start-Process $InstalledTentacleExe -ArgumentList $arguments -Wait

            Write-Output "All done! OctopusDeploy Tentacle is installed & configured."
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