# Parameters for Nessus Installation script
$ENV:NessusKey = {{NESSUS_KEY}}
$ENV:NessusGroups = "IRE-CM-LZ"
$ENV:NessusServer = "cloud.tenable.com"

# Parameters for OctopusDeploy script
$ENV:OctopusServerUrl = "octopus.covermore.com"
$ENV:OctopusServerApiKey = {{OCTOSERVER_APIKEY}}
$ENV:OctopusServerThumbprint = {{OCTOSERVER_THUMB}}
$ENV:OctopusTentacleInstanceName = $null # will default to instance name
$ENV:OctopusTentaclePort = 10933
$ENV:OctopusTentacleRootFolder = "C:\Octopus"
$ENV:OctopusTentacleRoles = @("")
$ENV:OctopusTentacleEnvironment = "Dev1"
