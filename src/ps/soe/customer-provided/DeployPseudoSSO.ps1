Import-Module WebAdministration
. (Join-Path $PSScriptRoot "SetupFunctions.ps1")

#*******Config items
#	Note: The script will create a directory within $rootPath\$envPrefix.
#	Please delete this directory before running this script if a new install is required
#   Please run after giving elevated permissions using Set-ExecutionPolicy Unrestricted

$envPrefix = "test2"							#the environment to setup test/test2/test3/staging/prod/training
$deploymentStack = "AU"							#the global deployment location AU/UK
$rootWebSitePath = "c:\inetpub\wwwroot\"		#the location of the root web folder
$rootContentPath = "c:\Contents\"	 			#the location of the root contents folder
												#a ; seperated list of web app names for each affiliate

#if production set it to blank
$prodConst = "prod"
$preprodConst = "preprod"
$stagingConst = "staging"
$trainingConst = "training"
$customKeyContainer = "MyKeys"
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
InitEncryption $customKeyContainer $PSScriptRoot

if (($envPrefix -eq "Dev1") -or ($envPrefix -eq "Test2") -or ($envPrefix -eq "Test3")){

	#API
	if ($deploymentStack -eq "AU"){
		#pseudosso_idp.covermore.com
		$name = "pseudosso_idp.covermore.com"
		$websiteName = "{0}{1}" -f $websitePrefix, $name
		$appPoolName = $websiteName
		$websitePath = Join-Path $envWebSitePath $name
		$webAppName = "simplesaml"
		$webAppPath = Join-Path $websitePath "www"

		CheckAndCreateAppPool $appPoolName
		CheckAndCreateDirectory $envWebSitePath $name
		CheckAndCreateWebSite $websiteName $websitePath $appPoolName
		CheckAndCreateWebApp $websiteName $webAppName $webAppPath $appPoolName
		AllowAccountAccessToKeyContainer $customKeyContainer $appPoolName

		#pseudosso_sp.covermore.com
		$name = "pseudosso_sp.covermore.com"
		$websiteName = "{0}{1}" -f $websitePrefix, $name
		$appPoolName = $websiteName
		$websitePath = Join-Path $envWebSitePath $name
		$webAppName = "simplesaml"
		$webAppPath = Join-Path $websitePath "www"
		
		CheckAndCreateAppPool $appPoolName
		CheckAndCreateDirectory $envWebSitePath $name
		CheckAndCreateWebSite $websiteName $websitePath $appPoolName
		CheckAndCreateWebApp $websiteName $webAppName $webAppPath $appPoolName
		AllowAccountAccessToKeyContainer $customKeyContainer $appPoolName
	}
}

Write-Output "Setup Complete"