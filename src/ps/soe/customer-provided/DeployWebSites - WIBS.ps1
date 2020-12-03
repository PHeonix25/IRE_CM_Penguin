Import-Module WebAdministration
. (Join-Path $PSScriptRoot "SetupFunctions.ps1")

#*******Config items
#	Note: The script will create a directory within $rootPath\$envPrefix.
#	Please delete this directory before running this script if a new install is required
#   Please run after giving elevated permissions using Set-ExecutionPolicy Unrestricted

$envPrefix = "prod"							#the environment to setup test/test2/test3/staging/prod/training
$deploymentStack = "US"							#the global deployment location AU/UK
$rootWebSitePath = "c:\inetpub\wwwroot\"		#the location of the root web folder
$rootContentPath = "c:\Contents\"	 			#the location of the root contents folder
												#a ; seperated list of web app names for each affiliate
$cmB2cSites = "agent;best-flights;broker;concorde;escape-travel;global-journeys;harvey-world-travel;quote;quote2;sta-travel;student-flights;travellers-choice;travelscene;travelsure;travel-there;curtin;edith-cowan;uxc;travelwise-family-friends;equipsuper;globus;world-expeditions;helloworld;holidayplanet;cruiseplanet;flightplanet;hotelplanet;thaiairways;byojet;pocruises;princess;norwegian;carnival;oceania;regent;royal;celebrity;azamara;entertainmentbook"

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

#THIRDPARTY
if ($deploymentStack -eq "AU"){
	#thirdpartyws.covermore.com
	$name = "thirdpartyws.covermore.com"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
}
if ($deploymentStack -eq "UK"){
	#thirdpartyws.covermore.co.uk
	$name = "thirdpartyws.covermore.co.uk"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
}
if ($deploymentStack -eq "US"){
	#thirdpartyws.us.covermore.com
	$name = "thirdpartyws.us.covermore.com"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
}


#WIBS
if ($deploymentStack -eq "AU"){
	#wibshandler.covermore.com.au
	$name = "wibshandler.covermore.com.au"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName


	#par1-wibshandler.covermore.com.au
	$name = "par1-wibshandler.covermore.com.au"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
}

Write-Output "Setup Complete"