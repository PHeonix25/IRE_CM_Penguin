Import-Module WebAdministration
. (Join-Path $PSScriptRoot "SetupFunctions.ps1")

#*******Config items
#	Note: The script will create a directory within $rootPath\$envPrefix.
#	Please delete this directory before running this script if a new install is required
#   Please run after giving elevated permissions using Set-ExecutionPolicy Unrestricted

$envPrefix = if ($ENV:CoverMoreEnvironment) { $ENV:CoverMoreEnvironment } else { "dev1" } #the environment to setup test/test2/test3/staging/prod/training
$deploymentStack = if ($ENV:CoverMoreDeploymentStack) { $ENV:CoverMoreDeploymentStack } else { "UK" } #the global deployment location AU/UK

$rootWebSitePath = "c:\inetpub\wwwroot\"		#the location of the root web folder
$rootContentPath = "c:\Contents\"	 			#the location of the root contents folder
#a semi-colon separated list of web app names for each affiliate
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


#API
if ($deploymentStack -eq "AU"){
	#api.covermore.com
	$name = "api.covermore.com"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	AllowAccountAccessToKeyContainer $customKeyContainer $appPoolName
	
	#par1-api.covermore.com
	$name = "par1-api.covermore.com"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	AllowAccountAccessToKeyContainer $customKeyContainer $appPoolName

	#api.travelinsurancepartners.com
	$name = "api.travelinsurancepartners.com"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	AllowAccountAccessToKeyContainer $customKeyContainer $appPoolName

	#penguinapi.covermore.com
	$name = "penguinapi.covermore.com"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	AllowAccountAccessToKeyContainer $customKeyContainer $appPoolName
}
if ($deploymentStack -eq "UK"){
	#api.covermore.co.uk
	$name = "api.covermore.co.uk"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	AllowAccountAccessToKeyContainer $customKeyContainer $appPoolName

	#penguinapi.covermore.co.uk
	$name = "penguinapi.covermore.co.uk"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	AllowAccountAccessToKeyContainer $customKeyContainer $appPoolName
}
if ($deploymentStack -eq "US"){
	#api.us.covermore.com
	$name = "api.us.covermore.com"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	AllowAccountAccessToKeyContainer $customKeyContainer $appPoolName

	#penguinapi.us.covermore.com
	$name = "penguinapi.us.covermore.com"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	AllowAccountAccessToKeyContainer $customKeyContainer $appPoolName
}


#ASSESSMENT
if ($deploymentStack -eq "AU"){
	#assessment.covermore.co.nz
	$name = "assessment.covermore.co.nz"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath "Assessment\CM"
	$contentPath = Join-Path $envContentPath "NZ\AssessmentContentRepository\cm"

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	CheckAndCreateVirtualDir $websiteName "" "contents" (Join-Path $contentPath "contents")
	CheckAndCreateVirtualDir $websiteName "" "css" (Join-Path $contentPath "css")
	CheckAndCreateVirtualDir $websiteName "" "help_files" (Join-Path $contentPath "help_files")
	CheckAndCreateVirtualDir $websiteName "" "images" (Join-Path $contentPath "images")
	CheckAndCreateVirtualDir $websiteName "" "script" (Join-Path $contentPath "script")
	CheckAndCreateVirtualDir $websiteName "" "webconfigs" (Join-Path $contentPath "webconfigs")

	#assessment.covermore.com.au
	$name = "assessment.covermore.com.au"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath "Assessment\CM"
	$contentPath = Join-Path $envContentPath "AU\AssessmentContentRepository\cm"

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	CheckAndCreateVirtualDir $websiteName "" "contents" (Join-Path $contentPath "contents")
	CheckAndCreateVirtualDir $websiteName "" "css" (Join-Path $contentPath "css")
	CheckAndCreateVirtualDir $websiteName "" "help_files" (Join-Path $contentPath "help_files")
	CheckAndCreateVirtualDir $websiteName "" "images" (Join-Path $contentPath "images")
	CheckAndCreateVirtualDir $websiteName "" "script" (Join-Path $contentPath "script")
	CheckAndCreateVirtualDir $websiteName "" "webconfigs" (Join-Path $contentPath "webconfigs")

	#par1-assessment.covermore.com.au
	$name = "par1-assessment.covermore.com.au"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath "Assessment\PAR1"
	$contentPath = Join-Path $envContentPath "AU\AssessmentContentRepository\PAR1"

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	CheckAndCreateVirtualDir $websiteName "" "contents" (Join-Path $contentPath "contents")
	CheckAndCreateVirtualDir $websiteName "" "css" (Join-Path $contentPath "css")
	CheckAndCreateVirtualDir $websiteName "" "help_files" (Join-Path $contentPath "help_files")
	CheckAndCreateVirtualDir $websiteName "" "images" (Join-Path $contentPath "images")
	CheckAndCreateVirtualDir $websiteName "" "script" (Join-Path $contentPath "script")
	CheckAndCreateVirtualDir $websiteName "" "webconfigs" (Join-Path $contentPath "webconfigs")

	#assessment.customercare.com.au-zurich
	$name = "assessment.customercare.com.au"
	$webAppName = "Zurich"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name
	$webAppPath = Join-Path $envWebSitePath "Assessment\CM"
	$contentPath = Join-Path $envContentPath "AU\AssessmentContentRepository\zurich"

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	$appPoolName = "{0}{1}-{2}" -f $websitePrefix, $name, $webAppName
	CheckAndCreateAppPool $appPoolName
	CheckAndCreateWebApp $websiteName $webAppName $webAppPath $appPoolName
	CheckAndCreateVirtualDir $websiteName $webAppName "contents" (Join-Path $contentPath "contents")
	CheckAndCreateVirtualDir $websiteName $webAppName "css" (Join-Path $contentPath "css")
	CheckAndCreateVirtualDir $websiteName $webAppName "help_files" (Join-Path $contentPath "help_files")
	CheckAndCreateVirtualDir $websiteName $webAppName "images" (Join-Path $contentPath "images")
	CheckAndCreateVirtualDir $websiteName $webAppName "script" (Join-Path $contentPath "script")
	CheckAndCreateVirtualDir $websiteName $webAppName "webconfigs" (Join-Path $contentPath "webconfigs")

	#assessment.travelinsurancepartners.com.au-medibank
	$name = "assessment.travelinsurancepartners.com.au"
	$webAppName = "medibank"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name
	$webAppPath = Join-Path $envWebSitePath "Assessment\TIP"
	$contentPath = Join-Path $envContentPath "AU\AssessmentContentRepository\tip\medibank"

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	$appPoolName = "{0}{1}-{2}" -f $websitePrefix, $name, $webAppName
	CheckAndCreateAppPool $appPoolName
	CheckAndCreateWebApp $websiteName $webAppName $webAppPath $appPoolName
	CheckAndCreateVirtualDir $websiteName $webAppName "contents" (Join-Path $contentPath "contents")
	CheckAndCreateVirtualDir $websiteName $webAppName "css" (Join-Path $contentPath "css")
	CheckAndCreateVirtualDir $websiteName $webAppName "help_files" (Join-Path $contentPath "help_files")
	CheckAndCreateVirtualDir $websiteName $webAppName "images" (Join-Path $contentPath "images")
	CheckAndCreateVirtualDir $websiteName $webAppName "script" (Join-Path $contentPath "script")
	CheckAndCreateVirtualDir $websiteName $webAppName "webconfigs" (Join-Path $contentPath "webconfigs")

	#assessment.travelinsurancepartners.com.au-auspost
	$name = "assessment.travelinsurancepartners.com.au"
	$webAppName = "auspost"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name
	$webAppPath = Join-Path $envWebSitePath "Assessment\TIP"
	$contentPath = Join-Path $envContentPath "AU\AssessmentContentRepository\tip\auspost"

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	$appPoolName = "{0}{1}-{2}" -f $websitePrefix, $name, $webAppName
	CheckAndCreateAppPool $appPoolName
	CheckAndCreateWebApp $websiteName $webAppName $webAppPath $appPoolName
	CheckAndCreateVirtualDir $websiteName $webAppName "contents" (Join-Path $contentPath "contents")
	CheckAndCreateVirtualDir $websiteName $webAppName "css" (Join-Path $contentPath "css")
	CheckAndCreateVirtualDir $websiteName $webAppName "help_files" (Join-Path $contentPath "help_files")
	CheckAndCreateVirtualDir $websiteName $webAppName "images" (Join-Path $contentPath "images")
	CheckAndCreateVirtualDir $websiteName $webAppName "script" (Join-Path $contentPath "script")
	CheckAndCreateVirtualDir $websiteName $webAppName "webconfigs" (Join-Path $contentPath "webconfigs")

	#assessment.travelinsurancepartners.com.au-aaa
	$name = "assessment.travelinsurancepartners.com.au"
	$webAppName = "AAA"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name
	$webAppPath = Join-Path $envWebSitePath "Assessment\TIP"
	$contentPath = Join-Path $envContentPath "AU\AssessmentContentRepository\tip\AAA"

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	$appPoolName = "{0}{1}-{2}" -f $websitePrefix, $name, $webAppName
	CheckAndCreateAppPool $appPoolName
	CheckAndCreateWebApp $websiteName $webAppName $webAppPath $appPoolName
	CheckAndCreateVirtualDir $websiteName $webAppName "contents" (Join-Path $contentPath "contents")
	CheckAndCreateVirtualDir $websiteName $webAppName "css" (Join-Path $contentPath "css")
	CheckAndCreateVirtualDir $websiteName $webAppName "help_files" (Join-Path $contentPath "help_files")
	CheckAndCreateVirtualDir $websiteName $webAppName "images" (Join-Path $contentPath "images")
	CheckAndCreateVirtualDir $websiteName $webAppName "script" (Join-Path $contentPath "script")
	CheckAndCreateVirtualDir $websiteName $webAppName "webconfigs" (Join-Path $contentPath "webconfigs")
	
	#assessment.travelinsurancepartners.com.au-ahm
	$name = "assessment.travelinsurancepartners.com.au"
	$webAppName = "AHM"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name
	$webAppPath = Join-Path $envWebSitePath "Assessment\TIP"
	$contentPath = Join-Path $envContentPath "AU\AssessmentContentRepository\tip\AHM"

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	$appPoolName = "{0}{1}-{2}" -f $websitePrefix, $name, $webAppName
	CheckAndCreateAppPool $appPoolName
	CheckAndCreateWebApp $websiteName $webAppName $webAppPath $appPoolName
	CheckAndCreateVirtualDir $websiteName $webAppName "contents" (Join-Path $contentPath "contents")
	CheckAndCreateVirtualDir $websiteName $webAppName "css" (Join-Path $contentPath "css")
	CheckAndCreateVirtualDir $websiteName $webAppName "help_files" (Join-Path $contentPath "help_files")
	CheckAndCreateVirtualDir $websiteName $webAppName "images" (Join-Path $contentPath "images")
	CheckAndCreateVirtualDir $websiteName $webAppName "script" (Join-Path $contentPath "script")
	CheckAndCreateVirtualDir $websiteName $webAppName "webconfigs" (Join-Path $contentPath "webconfigs")
}
if ($deploymentStack -eq "UK"){
	#assessment.covermore.co.uk
	$name = "assessment.covermore.co.uk"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath "Assessment\CM"
	$contentPath = Join-Path $envContentPath "UK\AssessmentContentRepository\cm"

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	CheckAndCreateVirtualDir $websiteName "" "contents" (Join-Path $contentPath "contents")
	CheckAndCreateVirtualDir $websiteName "" "css" (Join-Path $contentPath "css")
	CheckAndCreateVirtualDir $websiteName "" "help_files" (Join-Path $contentPath "help_files")
	CheckAndCreateVirtualDir $websiteName "" "images" (Join-Path $contentPath "images")
	CheckAndCreateVirtualDir $websiteName "" "script" (Join-Path $contentPath "script")
	CheckAndCreateVirtualDir $websiteName "" "webconfigs" (Join-Path $contentPath "webconfigs")
}


#B2B
if ($deploymentStack -eq "AU"){
	#b2b.covermore.com-au
	$name = "b2b.covermore.com"
	$webAppName = "AU"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name
	$webAppPath = Join-Path $envWebSitePath "PenguinWeb\CM\B2B"
	$contentPath = Join-Path $envContentPath "AU\B2BContentRepository\cm"

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	$appPoolName = "{0}{1}-{2}" -f $websitePrefix, $name, $webAppName
	CheckAndCreateAppPool $appPoolName
	CheckAndCreateWebApp $websiteName $webAppName $webAppPath $appPoolName
	CheckAndCreateVirtualDir $websiteName $webAppName "contents" (Join-Path $contentPath "contents")
	CheckAndCreateVirtualDir $websiteName $webAppName "webconfigs" (Join-Path $contentPath "webconfigs")

	#b2b.covermore.com-cn
	$name = "b2b.covermore.com"
	$webAppName = "CN"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name
	$webAppPath = Join-Path $envWebSitePath "PenguinWeb\CM\B2B"
	$contentPath = Join-Path $envContentPath "CN\B2BContentRepository\cm"

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	$appPoolName = "{0}{1}-{2}" -f $websitePrefix, $name, $webAppName
	CheckAndCreateAppPool $appPoolName
	CheckAndCreateWebApp $websiteName $webAppName $webAppPath $appPoolName
	CheckAndCreateVirtualDir $websiteName $webAppName "contents" (Join-Path $contentPath "contents")
	CheckAndCreateVirtualDir $websiteName $webAppName "webconfigs" (Join-Path $contentPath "webconfigs")

	#b2b.covermore.com-my
	$name = "b2b.covermore.com"
	$webAppName = "MY"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name
	$webAppPath = Join-Path $envWebSitePath "PenguinWeb\CM\B2B"
	$contentPath = Join-Path $envContentPath "MY\B2BContentRepository\cm"

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	$appPoolName = "{0}{1}-{2}" -f $websitePrefix, $name, $webAppName
	CheckAndCreateAppPool $appPoolName
	CheckAndCreateWebApp $websiteName $webAppName $webAppPath $appPoolName
	CheckAndCreateVirtualDir $websiteName $webAppName "contents" (Join-Path $contentPath "contents")
	CheckAndCreateVirtualDir $websiteName $webAppName "webconfigs" (Join-Path $contentPath "webconfigs")

	#b2b.covermore.com-nz
	$name = "b2b.covermore.com"
	$webAppName = "NZ"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name
	$webAppPath = Join-Path $envWebSitePath "PenguinWeb\CM\B2B"
	$contentPath = Join-Path $envContentPath "NZ\B2BContentRepository\cm"

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	$appPoolName = "{0}{1}-{2}" -f $websitePrefix, $name, $webAppName
	CheckAndCreateAppPool $appPoolName
	CheckAndCreateWebApp $websiteName $webAppName $webAppPath $appPoolName
	CheckAndCreateVirtualDir $websiteName $webAppName "contents" (Join-Path $contentPath "contents")
	CheckAndCreateVirtualDir $websiteName $webAppName "webconfigs" (Join-Path $contentPath "webconfigs")

	#b2b.covermore.com-sg
	$name = "b2b.covermore.com"
	$webAppName = "SG"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name
	$webAppPath = Join-Path $envWebSitePath "PenguinWeb\CM\B2B"
	$contentPath = Join-Path $envContentPath "SG\B2BContentRepository\cm"

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	$appPoolName = "{0}{1}-{2}" -f $websitePrefix, $name, $webAppName
	CheckAndCreateAppPool $appPoolName
	CheckAndCreateWebApp $websiteName $webAppName $webAppPath $appPoolName
	CheckAndCreateVirtualDir $websiteName $webAppName "contents" (Join-Path $contentPath "contents")
	CheckAndCreateVirtualDir $websiteName $webAppName "webconfigs" (Join-Path $contentPath "webconfigs")

	#b2b.covermore.com-id
	$name = "b2b.covermore.com"
	$webAppName = "ID"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name
	$webAppPath = Join-Path $envWebSitePath "PenguinWeb\CM\B2B"
	$contentPath = Join-Path $envContentPath "ID\B2BContentRepository\cm"

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	$appPoolName = "{0}{1}-{2}" -f $websitePrefix, $name, $webAppName
	CheckAndCreateAppPool $appPoolName
	CheckAndCreateWebApp $websiteName $webAppName $webAppPath $appPoolName
	CheckAndCreateVirtualDir $websiteName $webAppName "contents" (Join-Path $contentPath "contents")
	CheckAndCreateVirtualDir $websiteName $webAppName "webconfigs" (Join-Path $contentPath "webconfigs")

	#b2b.travelinsurancepartners.com.au-auspost
	$name = "b2b.travelinsurancepartners.com.au"
	$webAppName = "Auspost"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name
	$webAppPath = Join-Path $envWebSitePath "PenguinWeb\TIP\B2B"
	$contentPath = Join-Path $envContentPath "AU\B2BContentRepository\TIP\auspost"

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	$appPoolName = "{0}{1}-{2}" -f $websitePrefix, $name, $webAppName
	CheckAndCreateAppPool $appPoolName
	CheckAndCreateWebApp $websiteName $webAppName $webAppPath $appPoolName
	CheckAndCreateVirtualDir $websiteName $webAppName "contents" (Join-Path $contentPath "contents")
	CheckAndCreateVirtualDir $websiteName $webAppName "webconfigs" (Join-Path $contentPath "webconfigs")

	#b2b.travelinsurancepartners.com.au-medibank
	$name = "b2b.travelinsurancepartners.com.au"
	$webAppName = "Medibank"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name
	$webAppPath = Join-Path $envWebSitePath "PenguinWeb\TIP\B2B"
	$contentPath = Join-Path $envContentPath "AU\B2BContentRepository\TIP\medibank"

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	$appPoolName = "{0}{1}-{2}" -f $websitePrefix, $name, $webAppName
	CheckAndCreateAppPool $appPoolName
	CheckAndCreateWebApp $websiteName $webAppName $webAppPath $appPoolName
	CheckAndCreateVirtualDir $websiteName $webAppName "contents" (Join-Path $contentPath "contents")
	CheckAndCreateVirtualDir $websiteName $webAppName "webconfigs" (Join-Path $contentPath "webconfigs")

	#b2b.travelinsurancepartners.com.au-aaa
	$name = "b2b.travelinsurancepartners.com.au"
	$webAppName = "AAA"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name
	$webAppPath = Join-Path $envWebSitePath "PenguinWeb\TIP\B2B"
	$contentPath = Join-Path $envContentPath "AU\B2BContentRepository\TIP\AAA"

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	$appPoolName = "{0}{1}-{2}" -f $websitePrefix, $name, $webAppName
	CheckAndCreateAppPool $appPoolName
	CheckAndCreateWebApp $websiteName $webAppName $webAppPath $appPoolName
	CheckAndCreateVirtualDir $websiteName $webAppName "contents" (Join-Path $contentPath "contents")
	CheckAndCreateVirtualDir $websiteName $webAppName "webconfigs" (Join-Path $contentPath "webconfigs")
}
if ($deploymentStack -eq "UK"){
	#b2b.covermore.co.uk
	$name = "b2b.covermore.co.uk"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath "PenguinWeb\CM\B2B"
	$contentPath = Join-Path $envContentPath "UK\B2BContentRepository\cm"

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	CheckAndCreateVirtualDir $websiteName "" "contents" (Join-Path $contentPath "contents")
	CheckAndCreateVirtualDir $websiteName "" "webconfigs" (Join-Path $contentPath "webconfigs")
}
if ($deploymentStack -eq "US"){

	#b2b.covermore.us
	$name = "b2b.covermore.us"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath "PenguinWeb\CM\B2B"
	$contentPath = Join-Path $envContentPath "US\B2BContentRepository\cm"

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	CheckAndCreateVirtualDir $websiteName "" "contents" (Join-Path $contentPath "contents")
	CheckAndCreateVirtualDir $websiteName "" "webconfigs" (Join-Path $contentPath "webconfigs")
}


#CDN
if ($deploymentStack -eq "AU"){
	#cdn.covermore.com
	$name = "cdn.covermore.com"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName

	#cdn.travelinsurancepartners.com
	$name = "cdn.travelinsurancepartners.com"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
}
if ($deploymentStack -eq "UK"){
	#cdn.covermore.co.uk
	$name = "cdn.covermore.co.uk"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName

	$commonPath = Join-Path $envWebSitePath "common-$name"
	CheckAndCreateVirtualDir $websiteName "" "common" $commonPath
}
if ($deploymentStack -eq "US"){
	#cdn.covermore.com-us
	$name = "cdn.covermore.us"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath "cdn.covermore.com"

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath "cdn.covermore.com"
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
}


#CRM
if ($deploymentStack -eq "AU"){
	#crm.covermore.com
	$name = "crm.covermore.com"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
}
if ($deploymentStack -eq "UK"){
	#crm.covermore.co.uk
	$name = "crm.covermore.co.uk"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
}

if ($deploymentStack -eq "US"){
	#crm.us.covermore.com
	$name = "crm.us.covermore.com"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
}


#DOCGEN
if ($deploymentStack -eq "AU"){
	#docgen.covermore.com
	$name = "docgen.covermore.com"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	AllowAccountAccessToKeyContainer $customKeyContainer $appPoolName
}
if ($deploymentStack -eq "UK"){
	#docgen.covermore.co.uk
	$name = "docgen.covermore.co.uk"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	AllowAccountAccessToKeyContainer $customKeyContainer $appPoolName
}
if ($deploymentStack -eq "US"){
	#docgen.us.covermore.com
	$name = "docgen.us.covermore.com"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	AllowAccountAccessToKeyContainer $customKeyContainer $appPoolName
}


#EXTERNALWS
if ($deploymentStack -eq "AU"){
	#externalws.covermore.com
	$name = "externalws.covermore.com"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	AllowAccountAccessToKeyContainer $customKeyContainer $appPoolName
}
if ($deploymentStack -eq "UK"){
	#externalws.covermore.co.uk
	$name = "externalws.covermore.co.uk"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	AllowAccountAccessToKeyContainer $customKeyContainer $appPoolName
}
if ($deploymentStack -eq "US"){
	#externalws.us.covermore.com
	$name = "externalws.us.covermore.com"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	AllowAccountAccessToKeyContainer $customKeyContainer $appPoolName
}


#NSURVEY
if ($deploymentStack -eq "AU"){
	#nsurveyadmin.covermore.com
	$name = "nsurveyadmin.covermore.com"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
}
if ($deploymentStack -eq "UK"){
	#nsurveyadmin.covermore.co.uk
	$name = "nsurveyadmin.covermore.co.uk"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
}
if ($deploymentStack -eq "US"){
	#nsurveyadmin.us.covermore.com
	$name = "nsurveyadmin.us.covermore.com"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
}


#AVANT
if ($deploymentStack -eq "AU"){
	#avant.covermore.com.au
	$name = "avant.covermore.com.au"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
}


#PENGUINJOBS
if ($deploymentStack -eq "AU"){
	#penguinjobs.covermore.com
	$name = "penguinjobs.covermore.com"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	AllowAccountAccessToKeyContainer $customKeyContainer $appPoolName
}
if ($deploymentStack -eq "UK"){
	#penguinjobs.covermore.co.uk
	$name = "penguinjobs.covermore.co.uk"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	AllowAccountAccessToKeyContainer $customKeyContainer $appPoolName
}
if ($deploymentStack -eq "US"){
	#penguinjobs.us.covermore.com
	$name = "penguinjobs.us.covermore.com"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	AllowAccountAccessToKeyContainer $customKeyContainer $appPoolName
}


#B2C
if ($deploymentStack -eq "AU"){
	#secure.covermore.com.au
	$name = "secure.covermore.com.au"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name
	$webAppPath = Join-Path $envWebSitePath "PenguinWeb\cm\B2C"
	$contentPath = Join-Path $envContentPath "AU\B2CContentRepository\cm"

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName

	if ($cmB2cSites -ine ""){
		foreach ($webAppName in $cmB2cSites.Split(";")) { 
			$appPoolName = "{0}{1}-{2}" -f $websitePrefix, $name, $webAppName
			$b2cContentPath = Join-Path $contentPath $webAppName
			CheckAndCreateAppPool $appPoolName
			CheckAndCreateWebApp $websiteName $webAppName $webAppPath $appPoolName

			CheckAndCreateVirtualDir $websiteName $webAppName "contents" (Join-Path $b2cContentPath "contents")
			CheckAndCreateVirtualDir $websiteName $webAppName "css" (Join-Path $b2cContentPath "css")
			CheckAndCreateVirtualDir $websiteName $webAppName "help_files" (Join-Path $b2cContentPath "help_files")
			CheckAndCreateVirtualDir $websiteName $webAppName "images" (Join-Path $b2cContentPath "images")
			CheckAndCreateVirtualDir $websiteName $webAppName "script" (Join-Path $b2cContentPath "script")
			CheckAndCreateVirtualDir $websiteName $webAppName "webconfigs" (Join-Path $b2cContentPath "webconfigs")
		}
	}
}
if ($deploymentStack -eq "UK"){
	#No B2C for UK
	Write-Output "No B2C for UK... skipping" -foregroundcolor "green"
}
if ($deploymentStack -eq "US"){
	#No B2C for US
	Write-Output "No B2C for US... skipping" -foregroundcolor "green"
}


#WCF
if ($deploymentStack -eq "AU"){
	#ws.covermore.com
	$name = "ws.covermore.com"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name
	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	
	$webAppName = "services"
	$webAppPath = Join-Path $envWebSitePath ("{0}\{1}" -f $name, $webAppName)
	$appPoolName = "{0}{1}-Services" -f $websitePrefix, $name
	CheckAndCreateAppPool $appPoolName
	CheckAndCreateWebApp $websiteName $webAppName $webAppPath $appPoolName
	AllowAccountAccessToKeyContainer $customKeyContainer $appPoolName

	$webAppName = "par1-services"
	$webAppPath = Join-Path $envWebSitePath ("{0}\{1}" -f $name, $webAppName)
	$appPoolName = "{0}{1}-Par1-Services" -f $websitePrefix, $name
	CheckAndCreateAppPool $appPoolName
	CheckAndCreateWebApp $websiteName $webAppName $webAppPath $appPoolName
	AllowAccountAccessToKeyContainer $customKeyContainer $appPoolName

	$webAppName = "ext-services"
	$webAppPath = Join-Path $envWebSitePath ("{0}\{1}" -f $name, $webAppName)
	$appPoolName = "{0}{1}-Ext-Services" -f $websitePrefix, $name
	CheckAndCreateAppPool $appPoolName
	CheckAndCreateWebApp $websiteName $webAppName $webAppPath $appPoolName
	AllowAccountAccessToKeyContainer $customKeyContainer $appPoolName

	$webAppName = "par1-ext-services"
	$webAppPath = Join-Path $envWebSitePath ("{0}\{1}" -f $name, $webAppName)
	$appPoolName = "{0}{1}-Par1-Ext-Services" -f $websitePrefix, $name
	CheckAndCreateAppPool $appPoolName
	CheckAndCreateWebApp $websiteName $webAppName $webAppPath $appPoolName
	AllowAccountAccessToKeyContainer $customKeyContainer $appPoolName

	#ws.travelinsurancepartners.com
	$name = "ws.travelinsurancepartners.com"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name
	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName
	
	$webAppName = "services"
	$webAppPath = Join-Path $envWebSitePath ("{0}\{1}" -f $name, $webAppName)
	$appPoolName = "{0}{1}-Services" -f $websitePrefix, $name
	CheckAndCreateAppPool $appPoolName
	CheckAndCreateWebApp $websiteName $webAppName $webAppPath $appPoolName
	AllowAccountAccessToKeyContainer $customKeyContainer $appPoolName
}
if ($deploymentStack -eq "UK"){
	#ws.covermore.co.uk
	$name = "ws.covermore.co.uk"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name
	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName

	$webAppName = "services"
	$webAppPath = Join-Path $envWebSitePath ("{0}\{1}" -f $name, $webAppName)
	$appPoolName = "{0}{1}-Services" -f $websitePrefix, $name
	CheckAndCreateAppPool $appPoolName
	CheckAndCreateWebApp $websiteName $webAppName $webAppPath $appPoolName
	AllowAccountAccessToKeyContainer $customKeyContainer $appPoolName

	$webAppName = "ext-services"
	$webAppPath = Join-Path $envWebSitePath ("{0}\{1}" -f $name, $webAppName)	
	$appPoolName = "{0}{1}-Ext-Services" -f $websitePrefix, $name
	CheckAndCreateAppPool $appPoolName
	CheckAndCreateWebApp $websiteName $webAppName $webAppPath $appPoolName
	AllowAccountAccessToKeyContainer $customKeyContainer $appPoolName
}
if ($deploymentStack -eq "US"){
	#ws.us.covermore.com
	$name = "ws.us.covermore.com"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name
	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName

	$webAppName = "services"
	$webAppPath = Join-Path $envWebSitePath ("{0}\{1}" -f $name, $webAppName)
	$appPoolName = "{0}{1}-Services" -f $websitePrefix, $name
	CheckAndCreateAppPool $appPoolName	
	CheckAndCreateWebApp $websiteName $webAppName $webAppPath $appPoolName
	AllowAccountAccessToKeyContainer $customKeyContainer $appPoolName
	
	$webAppName = "ext-services"
	$webAppPath = Join-Path $envWebSitePath ("{0}\{1}" -f $name, $webAppName)
	$appPoolName = "{0}{1}-Ext-Services" -f $websitePrefix, $name
	CheckAndCreateAppPool $appPoolName
	CheckAndCreateWebApp $websiteName $webAppName $webAppPath $appPoolName
	AllowAccountAccessToKeyContainer $customKeyContainer $appPoolName
}


#GLOBALSIM
if ($deploymentStack -eq "AU"){
	#sim.covermore.com
	$name = "sim.covermore.com"
    $aucmfolder = "\au\GlobalSimContentRepository\CM\contents"
    $autipfolder = "\au\GlobalSimContentRepository\TIP\contents"
    $nzcmfolder = "\nz\GlobalSimContentRepository\CM\contents"
    $mycmfolder = "\my\GlobalSimContentRepository\CM\contents"
    $sgcmfolder = "\sg\GlobalSimContentRepository\CM\contents"
    $ukcmfolder = "\uk\GlobalSimContentRepository\CM\contents"

	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name
	$contentPathaucm  = "{0}{1}" -f $envContentPath, $aucmfolder
    $contentPathautip = "{0}{1}" -f $envContentPath, $autipfolder
    $contentPathnzcm  = "{0}{1}" -f $envContentPath, $nzcmfolder
    $contentPathmycm  = "{0}{1}" -f $envContentPath, $mycmfolder
    $contentPathsgcm  = "{0}{1}" -f $envContentPath, $sgcmfolder
    $contentPathukcm  = "{0}{1}" -f $envContentPath, $ukcmfolder

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName

	CheckAndCreateVirtualDir $websiteName "" "au_cm"  $contentPathaucm
    CheckAndCreateVirtualDir $websiteName "" "au_tip" $contentPathautip
    CheckAndCreateVirtualDir $websiteName "" "nz_cm"  $contentPathnzcm
    CheckAndCreateVirtualDir $websiteName "" "my_cm"  $contentPathmycm
    CheckAndCreateVirtualDir $websiteName "" "sg_cm"  $contentPathsgcm
    CheckAndCreateVirtualDir $websiteName "" "uk_cm"  $contentPathukcm
}


#MYPOLICY
if ($deploymentStack -eq "AU"){
	#mypolicy.covermore.com
	$name = "mypolicy.covermore.com"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name
	$webAppPath = Join-Path $envWebSitePath "mypolicy.covermore.com "
	$contentPath = Join-Path $envContentPath "AU\PortalContentRepository\CM"

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName

	CheckAndCreateVirtualDir $websiteName "" "contents" (Join-Path $contentPath "contents")
	CheckAndCreateVirtualDir $websiteName "" "css" (Join-Path $contentPath "css")
	CheckAndCreateVirtualDir $websiteName "" "help_files" (Join-Path $contentPath "help_files")
	CheckAndCreateVirtualDir $websiteName "" "images" (Join-Path $contentPath "images")
	CheckAndCreateVirtualDir $websiteName "" "script" (Join-Path $contentPath "script")
	CheckAndCreateVirtualDir $websiteName "" "webconfigs" (Join-Path $contentPath "webconfigs")

	
	#Mypolicy.travelinsurancepartners.com.au
	$name = "mypolicy.travelinsurancepartners.com.au"
	$websiteName = "{0}{1}" -f $websitePrefix, $name
	$appPoolName = $websiteName
	$websitePath = Join-Path $envWebSitePath $name
	$webAppPath = Join-Path $envWebSitePath "mypolicy.travelinsurancepartners.com.au"
	$contentPath = Join-Path $envContentPath "AU\PortalContentRepository\TIP"

	CheckAndCreateAppPool $appPoolName
	CheckAndCreateDirectory $envWebSitePath $name
	CheckAndCreateWebSite $websiteName $websitePath $appPoolName

	CheckAndCreateVirtualDir $websiteName "" "contents" (Join-Path $contentPath "contents")
	CheckAndCreateVirtualDir $websiteName "" "css" (Join-Path $contentPath "css")
	CheckAndCreateVirtualDir $websiteName "" "help_files" (Join-Path $contentPath "help_files")
	CheckAndCreateVirtualDir $websiteName "" "images" (Join-Path $contentPath "images")
	CheckAndCreateVirtualDir $websiteName "" "script" (Join-Path $contentPath "script")
	CheckAndCreateVirtualDir $websiteName "" "webconfigs" (Join-Path $contentPath "webconfigs")
}

Write-Output "Setup Complete"