function CheckAndCreateDirectory([string]$root, [string]$subdir) {
	$pathToCheckAndCreate = (Join-Path $root $subdir)

	if (Test-Path -path $pathToCheckAndCreate) {
		Write-Output "Directory exists: $pathToCheckAndCreate"
		return $pathToCheckAndCreate
	} else {
		New-Item -Path $pathToCheckAndCreate -type directory
		Write-Verbose "Directory created: '$pathToCheckAndCreate'."
	}
}

function CheckAndCreateWebSite([string]$websiteName, [string]$websitePath, [string]$appPoolName) {
	if (Test-Path -path IIS:\Sites\$websiteName) {
		Write-Output "Found existing website: '$siteName'. Pointing it to '$websitePath'."
		Set-ItemProperty "IIS:\Sites\$websiteName" -Name physicalPath -Value $websitePath
		Set-ItemProperty "IIS:\Sites\$websiteName" -Name applicationPool -Value $appPoolName
	} else {
		Write-Warning "Creating website '$websiteName' and pointing to '$websitePath'."
		CheckAndCreateDirectory $websitePath
		New-WebSite -Name $websiteName -PhysicalPath $websitePath -HostHeader $websiteName -ApplicationPool $appPoolName
	}
}

function CheckAndCreateWebApp([string]$siteName, [string]$appName, [string]$appPath, [string]$appPool) {
	if (ChildExists $siteName $appName 'Application') {	
		Write-Output "Found existing web app: '$siteName\$appName'. Pointing it to '$appPath'."
		Set-ItemProperty "IIS:\Sites\$siteName\$appName" -Name physicalPath -Value $appPath
		Set-ItemProperty "IIS:\Sites\$siteName\$appName" -Name applicationPool -Value $appPool
	} else {
		Write-Output "Creating web app '$siteName\$appName' and pointing to '$appPath'."
		CheckAndCreateDirectory $appPath
		New-WebApplication -Site $siteName -Name $appName -PhysicalPath $appPath -ApplicationPool $appPool
	}
}

function CheckAndCreateVirtualDir([string]$siteName, [string]$appName, [string]$dirName, [string]$dirPath) {
	CheckAndCreateDirectory $dirPath
	if ($appName) {
		if (ChildExists "$siteName\$appName" $dirName 'virtualDirectory') {
			Write-Output "Found existing virtual directory: '$siteName\$appName\$dirName'. Pointing it to '$dirPath'."
			Set-ItemProperty "IIS:\Sites\$siteName\$appName\$dirName" -Name physicalPath -Value $dirPath
		} else {
			Write-Output "Creating virtual directory: '$siteName\$appName\$dirName' and pointing it to '$dirPath'."
			New-Item "IIS:\Sites\$siteName\$appName\$dirName" -Type VirtualDirectory -PhysicalPath $dirPath -Force
		}
	} else {
		if (ChildExists $siteName $dirName 'virtualDirectory') {
			Write-Output "Found existing virtual directory: '$siteName\$dirName'. Pointing it to '$dirPath'."
			Set-ItemProperty "IIS:\Sites\$siteName\$dirName" -Name physicalPath -Value $dirPath
		} else {
			Write-Output "Creating virtual directory '$siteName\$dirName' and pointing to '$dirPath'."
			New-Item "IIS:\Sites\$siteName\$dirName" -Type VirtualDirectory -PhysicalPath $dirPath -Force
		}
	}
}

function CheckAndCreateAppPool([string]$appPoolName) {
	if (Test-Path -path IIS:\AppPools\$appPoolName) {
		Write-Output "Found existing AppPool: '$appPoolName'."
		
		$pool = Get-Item IIS:\AppPools\$appPoolName
		$pool.recycling.periodicrestart.time = [TimeSpan]::FromMinutes(0)
		$pool.processModel.idleTimeout = [TimeSpan]::FromMinutes(0)
		
		Set-ItemProperty IIS:\AppPools\$appPoolName managedRuntimeVersion v4.0
		Set-ItemProperty IIS:\AppPools\$appPoolName -Name recycling.periodicrestart.time $pool.recycling.periodicrestart.time
		Set-ItemProperty IIS:\AppPools\$appPoolName -Name recycling.periodicrestart.schedule -Value @{value = "03:00:00" }
		Set-ItemProperty IIS:\AppPools\$appPoolName -Name processModel.idleTimeout $pool.processModel.idleTimeout
	} else {
		Write-Output "Creating new AppPool: '$appPoolName'."
		$pool = New-WebAppPool -Name $appPoolName 
		$pool.recycling.periodicrestart.time = [TimeSpan]::FromMinutes(0)
		$pool.processModel.idleTimeout = [TimeSpan]::FromMinutes(0)
		
		Set-ItemProperty IIS:\AppPools\$appPoolName managedRuntimeVersion v4.0
		Set-ItemProperty IIS:\AppPools\$appPoolName -Name recycling.periodicrestart.time $pool.recycling.periodicrestart.time
		Set-ItemProperty IIS:\AppPools\$appPoolName -Name recycling.periodicrestart.schedule -Value @{value = "03:00:00" }
		Set-ItemProperty IIS:\AppPools\$appPoolName -Name processModel.idleTimeout $pool.processModel.idleTimeout
	}
}

function WebAppExists([string]$siteName, [string]$appName) {
	$webApps = Get-WebApplication -Site $siteName
	$appCount = 0
	foreach ($webap in $webApps) {
		if ($webap.Path -eq $appName) {
			$appCount++
		}
	}
	!($appCount -eq 0)
}

function ChildExists([string]$siteName, [string]$childName, [string]$childType) {
	Write-Verbose "Checking '$siteName'..."
	if ($childType) {
		$children = Get-Childitem ("IIS:\Sites\$siteName") | Where-Object { $_.Schema.Name -eq $childType }
	} else {
		$children = Get-Childitem ("IIS:\Sites\$siteName")
	}
	$childCount = 0
	foreach ($child in $children) {
		if ($child.Name -eq $childName) { $childCount++ }
	}
	return !($childCount -eq 0)
}

function CheckAndConvertToWebApp([string]$siteName, [string]$virtDirName, [string]$dirName, [string]$appPool) {
	if ($virtDirName) {
		if (WebAppExists $siteName ("/{0}/{1}" -f $virtDirName, $dirName)) {
			Write-Output "Found existing web app: '$siteName\$virtDirName\$dirName'."
			Set-ItemProperty "IIS:\Sites\$siteName\$virtDirName\$dirName" -Name applicationPool -Value $appPool
		} else {
			Write-Output "Converting site to web app: '$siteName\$virtDirName\$dirName'."
			ConvertTo-WebApplication IIS:\Sites\$siteName\$virtDirName\$dirName -ApplicationPool $appPool
		}
	} else {
		if (ChildExists $siteName $dirName "") {
			if (ChildExists $siteName $dirName "application") {
				Write-Output "Found existing web app: '$siteName\$dirName'."
				Set-ItemProperty "IIS:\Sites\$siteName\$dirName" -Name applicationPool -Value $appPool
			} else {
				Write-Output "Converting site to web app: '$siteName\$dirName'."
				ConvertTo-WebApplication IIS:\Sites\$siteName\$dirName -ApplicationPool $appPool
			}
		} else {
			Write-Error "No existing directory in '$siteName\$appName'! Nothing created!"
		}
	}
}

function InitEncryption([string]$KeyContainer, [string]$RSAFilePath) {
	if ($KeyContainer) {
		C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis -pc "$KeyContainer" -exp
		Write-Output "The previous registration is safe to ignore if it fails. This should mean that the registration already exists!"
		C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis -pi "$KeyContainer" "$RSAFilePath\CovermoreOnlineRSAConfigKey.xml"
	}
}

function AllowAccountAccessToKeyContainer([string]$KeyContainer, [string]$appPool) {
	if ($KeyContainer -and $appPool) {
		Write-Verbose "Granting access of AppPool '$appPool' to encryption container key '$KeyContainer'."
		C:\Windows\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis -pa "$KeyContainer" "IIS APPPOOL\$appPool"
	}
}