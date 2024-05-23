## Below script is almost worked but put method is failing

# Define necessary variables
$octopusURL = ""
$spaceName = "Default"
$destinationProjectName = "integrity-project"
$apiKey = ""
$variableJsonPath = "variable.json"
# Headers for API requests
$header = @{
    "X-Octopus-ApiKey" = $apiKey
}

# Fetch space details
$space = (Invoke-RestMethod -Method Get -Uri "$octopusURL/api/spaces/all" -Headers $header) | Where-Object {$_.Name -eq $spaceName}
if ($null -eq $space) {
    throw "Space not found: $spaceName"
}

# Fetch project list and get destination project details
$projectList = Invoke-RestMethod "$octopusURL/api/$($space.Id)/projects/all" -Headers $header
$destinationProject = $projectList | Where-Object { $_.Name -eq $destinationProjectName }
if ($null -eq $destinationProject) {
    throw "Project not found: $destinationProjectName"
}
$destinationProjectVariableSetId = $destinationProject.VariableSetId

# Fetch environment list
$destinationEnvironmentList = Invoke-RestMethod -Method Get -Uri "$octopusURL/api/$($space.Id)/environments/all" -Headers $header

# Load variables from variable.json
$variablesJson = Get-Content -Path "$variableJsonPath" -Raw | ConvertFrom-Json

# Fetch existing project variables
$variableSet = Invoke-RestMethod -Method Get -Uri "$octopusURL/api/variables/$destinationProjectVariableSetId" -Headers $header
if ($null -eq $variableSet) {
    throw "Variable set not found for project: $destinationProjectName"
}
$existingVariables = $variableSet.Variables

# Function to get environment ID by name
function Get-EnvironmentIdByName {
    param (
        [string]$environmentName
    )
    $environment = $destinationEnvironmentList | Where-Object { $_.Name -eq $environmentName }
    return $environment.Id
}

# Process each variable from the JSON file
foreach ($variable in $variablesJson.Variables) {
    $variableName = $variable.Name
    $variableValue = $variable.Value
    $variableScope = $variable.Scope.Environment

    foreach ($scopeEnvironment in $variableScope) {
        $environmentId = Get-EnvironmentIdByName -environmentName $scopeEnvironment
        if ($null -eq $environmentId) {
            Write-Warning "Environment '$scopeEnvironment' not found. Skipping variable '$variableName'."
            continue
        }

        $matchingVariable = $existingVariables | Where-Object { $_.Name -eq $variableName -and $_.Scope.Environment -contains $environmentId }

        if ($matchingVariable) {
            # Variable exists, check if value and environment match
            if ($matchingVariable.Value -ne $variableValue) {
                # Update the value
                $matchingVariable.Value = $variableValue
                Write-Output "Updated variable '$variableName' to value '$variableValue' for environment '$scopeEnvironment'"
            } else {
                Write-Output "Variable '$variableName' already exists with the same value '$variableValue' for environment '$scopeEnvironment'. No update needed."
            }
        } else {
            # Add new variable
            $newVariable = @{
                Id = [System.Guid]::NewGuid().ToString()
                Name = $variableName
                Value = $variableValue
                "Type" = "String"
                Scope = @{
                    Environment = @($environmentId)
                }
                IsEditable = $true
            }
            $existingVariables += [pscustomobject]$newVariable
            Write-Output "Added new variable '$variableName' with value '$variableValue' for environment '$scopeEnvironment'"
        }
    }
}

# Ensure variables are in the correct format
$variableSet.Variables = @($existingVariables)

# Convert the variable set to JSON
$jsonPayload = $variableSet | ConvertTo-Json -Depth 10

# Log the JSON payload for debugging
Write-Output "JSON Payload:"
Write-Output $jsonPayload
$octopusuri = "$octopusURL$($destinationProject.Links.Variables)"
# Send the PUT request to update the project variables
try {
    Write-Host "Adding variables to $octopusURL$($destinationProject.Links.Variables)"
    #$updateResponse = Invoke-RestMethod -Method Put -Uri "$octopusURL/api/variables/$destinationProjectVariableSetId" -Headers $header -Body $jsonPayload
    Invoke-RestMethod -Method Put -Uri "$octopusuri" -Headers $header -Body $jsonPayload
    Write-Output "Project variables updated successfully."
} catch {
    Write-Error "Failed to update project variables: $_"
}
