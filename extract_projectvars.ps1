# Set your Octopus Deploy API key and server URL 
$apiKey =  "$env:OCTOPUS_API_KEY"
$octopusURL = "$env:OCTOPUS_SERVER_URL"

# Set the project name for which you want to extract variables 
$projectName = "$env:ProjectName" 

# Function to get project ID 
function GetProjectId { 
	$projects = Invoke-RestMethod -Uri "$octopusURL/projects" -Headers @{ "X-Octopus-ApiKey" = $apiKey } 
	$project = $projects | Where-Object { $_.Name -eq $projectName } 
	return $project.Id 
	} 
	# Function to get project variables 
	function GetProjectVariables { 
	$projectId = GetProjectId 
	$variables = Invoke-RestMethod -Uri "$octopusURL/projects/$projectId/variables" -Headers @{ "X-Octopus-ApiKey" = $apiKey
	 } 
		return $variables 
	} 
	
	# Call function to get project variables 
	$projectVariables = GetProjectVariables 
	
	# Output project variables 
$projectVariables | Select-Object Name, Value 