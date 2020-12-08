
<#PSScriptInfo

.VERSION 1.0

.GUID ac611726-e251-4653-b72f-1c1c3286e8bb

.AUTHOR pat.hermens@slalom.com

.COMPANYNAME Slalom Build

.TAGS Octopus Deploy Server Release Deployment

#>

<# 

.SYNOPSIS 
 Redeploy an OctopusDeploy release into an environment

.DESCRIPTION
 This script queries the server for the latest release 
 of a given project in a given environment
 and asks the server to redeploy it to that environment

.PARAMETER ProjectName
 This is the name of the OctopusDeploy project that you would like to redeploy. 
 You can find this in the URL when viewing the OctopusDeploy UI after /project/.
 NOTE: This can ALSO be a semi-colon separated list of projects to deploy!

.PARAMETER EnvironmentName
 This is the name of the Environment that you would like OctopusDeploy to 
 redeploy the project into.

.PARAMETER OctopusServerApiKey
 [OPTIONAL] 
 Should ideally be read from Environment Variables, 
 but can be fed on the command line for debugging.

.PARAMETER OctopusServerUrl
 [OPTIONAL] 
 Should ideally be read from Environment Variables, 
 but can be fed on the command line for debugging.

.PARAMETER SpaceId
 [OPTIONAL] [DEFAULT VALUE: 'Spaces-1']
 Use this value to override the default "Spaces-1" 
 space in environments that have more than one 'space'.

.INPUTS
 None

.OUTPUTS
 None

.EXAMPLE 
 PS> # When using command-line parameters
 PS> Update-OctopusDeployReleases -ProjectName "cdn-uk" -EnvironmentName "dev1"

 .EXAMPLE 
 PS> # When requesting multiple deployments
 PS> Update-OctopusDeployReleases -ProjectName "cdn-uk;cdn-au" -EnvironmentName "dev1"

.EXAMPLE 
 PS> # When using aliases
 PS> Update-OctopusDeployReleases -project "cdn-uk" -env "dev1"

#> 
function Update-OctopusDeployReleases {
    [CmdletBinding()]
    param (
        [Alias("project")][string]$ProjectName, 
        [Alias("env")][string]$EnvironmentName,
        [string]$OctopusServerApiKey,
        [string]$OctopusServerUrl,
        [string]$SpaceId = "Spaces-1"
    )
    
    BEGIN {
        Write-Verbose "=> '$PSCommandPath' has started.";
    
        # Load required types
        Add-Type -AssemblyName "System.Web";

        # Validate environment variables
        if (Get-ChildItem -Path "ENV:Octo*") {
            if ((-not $OctopusServerApiKey) -and $ENV:OctopusServerApiKey) {
                $OctopusServerApiKey = $ENV:OctopusServerApiKey
                Write-Verbose "OctopusDeploy Server API KEY loaded from matching environment variable."
            }
            if ((-not $OctopusServerUrl) -and $ENV:OctopusServerUrl) {
                $OctopusServerUrl = $ENV:OctopusServerUrl
                Write-Verbose "OctopusDeploy Server URL loaded from matching environment variable."
            }
            if ((-not $EnvironmentName) -and $ENV:OctopusTentacleEnvironment) {
                $EnvironmentName = $ENV:OctopusTentacleEnvironment
                Write-Verbose "OctopusDeploy Tentacle ENVIRONMENT loaded from matching environment variable."
            }
            if ((-not $ProjectName) -and $ENV:OctopusTentacleProjects) {
                $ProjectName = $ENV:OctopusTentacleProjects
                Write-Verbose "OctopusDeploy Project list loaded from matching environment variable."
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
        if (-not $EnvironmentName) {
            Write-Error "OctopusDeploy Environment needs to be specified. Script cannot continue."
            throw [System.ArgumentNullException] "EnvironmentName"
        }
        if (-not $ProjectName) {
            Write-Error "OctopusDeploy Projects need to be specified. Script cannot continue."
            throw [System.ArgumentNullException] "ProjectName"
        }
        
        $header = @{ "X-Octopus-ApiKey" = $OctopusServerApiKey }
    }

    PROCESS {
        try {

            foreach ($name in ($ProjectName -split ';')) { 

                $projects = (Invoke-RestMethod "$OctopusServerUrl/api/$spaceId/projects?name=$([System.Web.HTTPUtility]::UrlEncode($name))&skip=0&take=1" -Headers $header)
                $projectId = $projects.Items[0].Id
                Write-Output "The projectId for '$name' is '$projectId'."

                $environments = (Invoke-RestMethod "$OctopusServerUrl/api/$spaceId/environments?name=$([System.Web.HTTPUtility]::UrlEncode($EnvironmentName))&skip=0&take=1" -Headers $header)
                $environmentId = $environments.Items[0].Id
                Write-Output "The environmentId for '$EnvironmentName' is '$environmentId'."

                $deployment = (Invoke-RestMethod "$OctopusServerUrl/api/$spaceId/deployments?projects=$projectId&environments=$environmentId&skip=0&take=1" -Headers $header)
                $releaseId = $deployment.Items[0].ReleaseId
                Write-Output "The most recent release for '$name' in the '$EnvironmentName' environment is '$releaseId'."

                $body = @{
                    EnvironmentId = "$environmentId"
                    ExcludedMachineIds = @()
                    ForcePackageDownload = $False
                    ForcePackageRedeployment = $false
                    FormValues = @{}
                    QueueTime = $null
                    QueueTimeExpiry = $null
                    ReleaseId = "$releaseId"
                    SkipActions = @()
                    SpecificMachineIds = @() # This machine only?
                    TenantId = $null
                    UseGuidedFailure = $false
                } | ConvertTo-Json

                $redeployment = (Invoke-RestMethod "$OctopusServerUrl/api/$spaceId/deployments" -Headers $header -Method Post -Body $body -ContentType "application/json")
                $taskId = $redeployment.TaskId
                $deploymentIsActive = $true

                while ($deploymentIsActive) {
                    $deploymentStatus = (Invoke-RestMethod "$OctopusServerUrl/api/tasks/$taskId/details?verbose=false" -Headers $header)
                    $deploymentStatusState = $deploymentStatus.Task.State

                    if ($deploymentStatusState -eq "Success" -or $deploymentStatusState -eq "Failed"){
                        $deploymentIsActive = $false
                    }
                    else{
                        Write-Output "Deployment is still active...checking again in 15 seconds"
                        Start-Sleep -Seconds 15
                    }
                    if ($deploymentStatusState -eq "Failed") {
                        Write-Error "Redeployment of '$name' errored. Please check your OctopusDeploy Server logs for failure reason, fix that, and try again." 
                    }
                } 

                Write-Output "Redeployment of '$name' has finished. Status was '$deploymentStatusState'."
            }

        }
        catch {
            Write-Error "An error occurred that could not be automatically resolved: $_"
            throw $_;
        }
    }

    END {
        Write-Verbose "=> '$PSCommandPath' has completed successfully.";
    }
};