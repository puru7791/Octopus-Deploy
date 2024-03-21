# Define Octopus API URL and API Key
$octopusAPIUrl = "$env:OCTOPUS_SERVER_URL"
$apiKey = "$env:OCTOPUS_API_KEY"

# Define the project ID for which you want to retrieve variables and included VariableSets
$projectId = "Projects-1"

# Define the output JSON file path
$outputFilePath = "variables_and_variablesets.json"

# Function to retrieve variables for a project
function Get-OctopusProjectVariables {
    param (
        [string]$projectId
    )

    $url = "$octopusAPIUrl/projects/$projectId/variables"
    $variables = Invoke-RestMethod -Uri $url -Headers @{ "X-Octopus-ApiKey" = $apiKey }
    return $variables
}

# Function to retrieve included VariableSets for a project
function Get-OctopusProjectIncludedVariableSets {
    param (
        [string]$projectId
    )

    $url = "$octopusAPIUrl/projects/$projectId/variableset"
    $variableSet = Invoke-RestMethod -Uri $url -Headers @{ "X-Octopus-ApiKey" = $apiKey }
    return $variableSet
}

# Retrieve variables and included VariableSets
$variables = Get-OctopusProjectVariables -projectId $projectId
$variableSet = Get-OctopusProjectIncludedVariableSets -projectId $projectId

# Create a hashtable to store variables and included VariableSets
$output = @{
    "Variables" = $variables
    "IncludedVariableSets" = $variableSet
}

# Convert hashtable to JSON and export to a file
$output | ConvertTo-Json | Out-File -FilePath $outputFilePath

Write-Host "Variables and included VariableSets exported to $outputFilePath"
