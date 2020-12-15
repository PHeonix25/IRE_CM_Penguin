Import-Module WebAdministration
. (Join-Path $PSScriptRoot "SetupFunctions.ps1")

#*******Config items
#	Note: The script will create a directory within $rootPath\$envPrefix.
#	Please delete this directory before running this script if a new install is required
#   Please run after giving elevated permissions using Set-ExecutionPolicy Unrestricted

$envPrefix = if ($ENV:CoverMoreEnvironment) { $ENV:CoverMoreEnvironment } else { "dev1" } #the environment to setup test/test2/test3/staging/prod/training
$deploymentStack = if ($ENV:CoverMoreDeploymentStack) { $ENV:CoverMoreDeploymentStack } else { "UK" } #the global deployment location AU/UK
$rootWebSitePath = "c:\inetpub\wwwroot\"	#the location of the root web folder
$rootContentPath = "c:\Contents\"	 		#the location of the root contents folder

#if production set it to blank
$prodConst = "prod"
$preprodConst = "preprod"
$stagingConst = "staging"
$trainingConst = "training"
$websitePrefix = $envPrefix + "-"
$envWebSitePath = Join-Path $rootWebSitePath $envPrefix
$envContentPath = Join-Path $rootContentPath $envPrefix
if ($envPrefix -eq $prodConst){
	$websitePrefix = ""
	$envPrefix = ""
	$envWebSitePath = $rootWebSitePath
	$envContentPath = $rootContentPath
}

Write-Output "Starting Website Setup"

#pay-ws
if ($deploymentStack -eq "AU"){
	#pay-ws.covermore.com.au
	$name = "pay-ws.covermore.com.au"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName

	#pay-trusted-ws.covermore.com.au
	$name = "pay-trusted-ws.covermore.com.au"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName

}
if ($deploymentStack -eq "UK"){
	#pay-ws.covermore.co.uk
	$name = "pay-ws.covermore.co.uk"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
}
Write-Output "Setup Complete"