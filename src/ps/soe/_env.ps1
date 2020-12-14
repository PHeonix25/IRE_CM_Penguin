# Fetch Metadata
$instanceId = (Invoke-RestMethod "http://169.254.169.254/latest/meta-data/instance-id")
$instance = (Get-EC2Instance -InstanceId $instanceId).Instances[0]
$instanceName = ($instance.Tags | Where-Object { $_.Key -eq "Name"} | Select-Object -ExpandProperty "Value")

# For our AWS/S3 stuff:
$ENV:PenguinInfraBucketName = ""

# For Cover-More provided scripts:
$ENV:CoverMoreEnvironment = ""
$ENV:CoverMoreDeploymentStack = ""

# Parameters for Nessus Installation script
$ENV:NessusKey = ""
$ENV:NessusGroups = ""
$ENV:NessusInstanceName = "$instanceName--$instanceId"

# Parameters for OctopusDeploy script
$ENV:OctopusServerUrl = ""
$ENV:OctopusServerApiKey = ""
$ENV:OctopusServerThumbprint = ""
$ENV:OctopusTentacleInstanceName = "$instanceName--$instanceId"
$ENV:OctopusTentaclePort = 10943
$ENV:OctopusTentacleRootFolder = ""
$ENV:OctopusTentacleRoles = ""
$ENV:OctopusTentacleEnvironment = ""
$ENV:OctopusTentacleProjects = ""