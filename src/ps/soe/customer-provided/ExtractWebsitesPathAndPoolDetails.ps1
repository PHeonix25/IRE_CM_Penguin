Import-Module WebAdministration

Write-Output "Checking..."
$webSites = Get-Website
foreach($childWebsite in $webSites)
{
	Write-Output "Website ," $childWebsite.Name","$childWebsite.physicalPath","$childWebsite.applicationPool

	$webApps = Get-WebApplication -Site $childWebsite.Name
	foreach($childWebApp in $webApps) {
		if (!($childWebApp -eq $null)) {
			Write-Output "WebApp ," $childWebApp.path","$childWebApp.physicalPath","$childWebApp.applicationPool
			if ($childWebApp.path.Length -gt 0) {
				$appVirDirs = Get-WebVirtualDirectory -Site $childWebsite.Name -Application $childWebApp.path.substring(1)
				foreach($childAppVirDir in $appVirDirs) {
					if (!($childAppVirDir -eq $null)) {
						Write-Output "WebSiteVirDir ," $childAppVirDir.path","$childAppVirDir.physicalPath","
					}
				}
			}
		}
	}
	
	$siteVirDirs = Get-WebVirtualDirectory -Site $childWebsite.Name
	foreach($childSiteVirDir in $siteVirDirs) {
		if (!($childSiteVirDir -eq $null)) {
			Write-Output "WebSiteVirDir ," $childSiteVirDir.path","$childSiteVirDir.physicalPath","
		}
	}
}
Write-Output "Done..."
