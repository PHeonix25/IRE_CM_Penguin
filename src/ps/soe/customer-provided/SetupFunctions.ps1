function CheckAndCreateDirectory([string]$root, [string]$subdir) {
	$pathToCheckAndCreate = Join-Path $root $subdir

	if (-not (Test-Path -path $pathToCheckAndCreate))
	{
		Write-Output "Directory created: $pathToCheckAndCreate" -foregroundcolor "magenta" -backgroundcolor "yellow"
		New-Item -Path $pathToCheckAndCreate -type directory
	} else {
		Write-Output "Directory exists: $pathToCheckAndCreate" -foregroundcolor "green"
		return $pathToCheckAndCreate
	}
}

function CheckAndCreateWebSite([string]$websiteName, [string]$websitePath, [string]$appPoolName) {
	if (Test-Path -path IIS:\Sites\$websiteName) {
		Write-Output "Existing website found: $siteName pointing to $websitePath" -foregroundcolor "green"
		Set-ItemProperty "IIS:\Sites\$websiteName" -Name physicalPath -Value $websitePath
		Set-ItemProperty "IIS:\Sites\$websiteName" -Name applicationPool -Value $appPoolName
	}
    else {
		Write-Output "Creating website: $websiteName  pointing to $websitePath" -foregroundcolor "magenta" -backgroundcolor "yellow"
		CheckAndCreateDirectory $websitePath
		New-WebSite -Name $websiteName -PhysicalPath $websitePath -HostHeader $websiteName -ApplicationPool $appPoolName
	}
}

function CheckAndCreateWebApp([string]$siteName, [string]$appName, [string]$appPath, [string]$appPool) {
	if (-not (ChildExists $siteName $appName 'Application')) {
		Write-Output "Creating web app: $siteName\$appName pointing to $appPath" -foregroundcolor "magenta" -backgroundcolor "yellow"
		CheckAndCreateDirectory $appPath
		New-WebApplication -Site $siteName -Name $appName -PhysicalPath $appPath -ApplicationPool $appPool
	} else {
    	Write-Output "Found existing web app: $siteName\$appName pointing to $appPath" -foregroundcolor "green"
		Set-ItemProperty "IIS:\Sites\$siteName\$appName" -Name physicalPath -Value $appPath
		Set-ItemProperty "IIS:\Sites\$siteName\$appName" -Name applicationPool -Value $appPool
	}
}

function CheckAndCreateVirtualDir([string]$siteName, [string]$appName, [string]$dirName, [string]$dirPath) {
    CheckAndCreateDirectory $dirPath
	if ($appName -eq "") {
		if (-not (ChildExists $siteName $dirName 'virtualDirectory')) {
			Write-Output "Creating virtual directory: $siteName\$dirName pointing to $dirPath" -foregroundcolor "magenta" -backgroundcolor "yellow"
			New-Item "IIS:\Sites\$siteName\$dirName" -Type VirtualDirectory -PhysicalPath $dirPath -Force
		} else {
        	Write-Output "Found existing virtual directory: $siteName\$dirName pointing to $dirPath" -foregroundcolor "green"
			Set-ItemProperty "IIS:\Sites\$siteName\$dirName" -Name physicalPath -Value $dirPath
		}
	} else {
		if (-not (ChildExists "$siteName\$appName" $dirName 'virtualDirectory')) {
			Write-Output "Creating virtual directory: $siteName\$appName\$dirName pointing to $dirPath" -foregroundcolor "magenta" -backgroundcolor "yellow"
			New-Item "IIS:\Sites\$siteName\$appName\$dirName" -Type VirtualDirectory -PhysicalPath $dirPath -Force
		} else {
        	Write-Output "Found existing virtual directory: $siteName\$appName\$dirName pointing to $dirPath" -foregroundcolor "green"
			Set-ItemProperty "IIS:\Sites\$siteName\$appName\$dirName" -Name physicalPath -Value $dirPath
		}
	}
}

function CheckAndCreateAppPool([string]$appPoolName) {
	if (-not (Test-Path -path IIS:\AppPools\$appPoolName))
	{
		Write-Output "Creating apppool: $appPoolName"
		$pool = New-WebAppPool -Name $appPoolName 
		$pool.recycling.periodicrestart.time = [TimeSpan]::FromMinutes(0)
		$pool.processModel.idleTimeout = [TimeSpan]::FromMinutes(0)
		
		Set-ItemProperty IIS:\AppPools\$appPoolName managedRuntimeVersion v4.0
		Set-ItemProperty IIS:\AppPools\$appPoolName -Name recycling.periodicrestart.time $pool.recycling.periodicrestart.time
		Set-ItemProperty IIS:\AppPools\$appPoolName -Name recycling.periodicrestart.schedule -Value @{value="03:00:00"}
		Set-ItemProperty IIS:\AppPools\$appPoolName -Name processModel.idleTimeout $pool.processModel.idleTimeout
	} else {
        Write-Output "Found existing apppool: $appPoolName"
		
		$pool = Get-Item IIS:\AppPools\$appPoolName
		$pool.recycling.periodicrestart.time = [TimeSpan]::FromMinutes(0)
		$pool.processModel.idleTimeout = [TimeSpan]::FromMinutes(0)
		
		Set-ItemProperty IIS:\AppPools\$appPoolName managedRuntimeVersion v4.0
		Set-ItemProperty IIS:\AppPools\$appPoolName -Name recycling.periodicrestart.time $pool.recycling.periodicrestart.time
		Set-ItemProperty IIS:\AppPools\$appPoolName -Name recycling.periodicrestart.schedule -Value @{value="03:00:00"}
		Set-ItemProperty IIS:\AppPools\$appPoolName -Name processModel.idleTimeout $pool.processModel.idleTimeout
	}
}

function WebAppExists([string]$siteName, [string]$appName) {
	$webApps = Get-WebApplication -Site $siteName
	$appCount = 0
	foreach($webap in $webApps)
	{
		if ($webap.Path -eq $appName){
			$appCount++
		}
	}
	!($appCount -eq 0)
}

function ChildExists([string]$siteName, [string]$childName, [string]$childType) {
	Write-Output "Checking : $siteName"
	if ($childType -eq "") {
		$children = Get-Childitem ("IIS:\Sites\"+ $siteName)
	} else {
		$children = Get-Childitem ("IIS:\Sites\"+ $siteName) | where {$_.Schema.Name -eq $childType}
	}
	$childCount = 0
	foreach($child in $children)
	{
		if ($child.Name -eq $childName) { $childCount++ }
	}
	!($childCount -eq 0)
}

function CheckAndConvertToWebApp([string]$siteName, [string]$virtDirName, [string]$dirName, [string]$appPool) {
	if ($virtDirName -eq "") {
		if (ChildExists $siteName $dirName "") {
			if (ChildExists $siteName $dirName "application") {
				Write-Output "Found existing web app: $siteName\$dirName"
				Set-ItemProperty "IIS:\Sites\$siteName\$dirName" -Name applicationPool -Value $appPool
			} else {
				Write-Output "Converting to web app: $siteName\$dirName"
				ConvertTo-WebApplication IIS:\Sites\$siteName\$dirName -ApplicationPool $appPool
			}
		} else {
	    	Write-Output "No existing directory in $siteName\$appName... Nothing created" -foregroundcolor "red"
		}
	} else {
		if (WebAppExists $siteName ("/{0}/{1}" -f $virtDirName, $dirName)) {
			Write-Output "Found existing web app: $siteName\$virtDirName\$dirName"
			Set-ItemProperty "IIS:\Sites\$siteName\$virtDirName\$dirName" -Name applicationPool -Value $appPool
		} else {
			Write-Output "Converting to web app: $siteName\$virtDirName\$dirName"
			ConvertTo-WebApplication IIS:\Sites\$siteName\$virtDirName\$dirName -ApplicationPool $appPool
		}
	}
}

function InitEncryption([string]$KeyContainer, [string]$RSAFilePath){
	if ($KeyContainer -ne "") {
		C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis -pc "$KeyContainer" -exp
		Write-Output "The previous registration is safe to ignore if it fails because it was already there"
		C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis -pi "$KeyContainer" "$RSAFilePath\CovermoreOnlineRSAConfigKey.xml"
	}
}

function AllowAccountAccessToKeyContainer([string]$KeyContainer, [string]$appPool) {
	if (($KeyContainer -ne "") -and ($appPool -ne "")) {
		Write-Output "Granting access of app pool: $appPool to encryption container key $KeyContainer" -foregroundcolor "blue" -backgroundcolor "green"
		C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis -pa "$KeyContainer" "IIS APPPOOL\$appPool"
	}
}