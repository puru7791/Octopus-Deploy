# Set your Octopus Deploy details
$octopusUrl = "$env:OCTOPUS_SERVER_URL"
$apiKey = "$env:OCTOPUS_API_KEY"
$projectName = "$env:ProjectName"
$spaceName = "Default"
# Define the output JSON file path
$outputFilePath = "exportedVariables.json"

# Function to make REST API requests
function Invoke-OctopusApi {
    param (
        [string]$Url,
        [string]$Method = "GET",
        [string]$Body = $null
    )

    $header = @{
        "X-Octopus-ApiKey" = $apiKey
    }

    try {
        $response = Invoke-RestMethod -Uri $Url -Method $Method -Headers $header -ContentType "application/json" -Body $Body -ErrorAction Stop
        return $response
    } catch {
        Write-Host "Error occurred: $($_.Exception.Message)"
        exit
    }
}

# Get space
$spaceUrl = "$octopusURL/api/spaces/all"
$spaceList = Invoke-OctopusApi -Url $spaceUrl
#$spaceList = Invoke-RestMethod "$octopusURL/api/spaces/all" -Headers $header
$space = $spaceList | Where-Object { $_.Name -eq $spaceName }
if ($space -eq $null) {
    Write-Host "Space '$spaceName' not found."
    exit
}

# Get Source project
$sourceProjectUrl = "$octopusURL/api/$($space.Id)/projects/all"
$projectList = Invoke-OctopusApi -Url $sourceProjectUrl
#$projectList = Invoke-RestMethod "$octopusURL/api/$($space.Id)/projects/all" -Headers $header
$sourceProject = $projectList | Where-Object { $_.Name -eq $projectName }
#$sourceProjectVariableSetId = $sourceProject.VariableSetId 

# Check if project is found
if ($sourceProject -eq $null) {
    Write-Host "Project '$projectName' not found."
    exit
}

# Get all variables and library variable sets
$variablesUrl = "$octopusUrl/api/$($space.Id)/projects/$($sourceProject.Id)/variables" # variables/$projectName/all"
#$variablesUrl = "$octopusUrl/api/variables/$projectName/all"
$variablesResponse = Invoke-OctopusApi -Url $variablesUrl

# Check if data is returned
if ($variablesResponse -eq $null) {
    Write-Host "No data returned from the URL $variablesResponse."
    exit
}

# Convert response to JSON and save to file
$variablesResponse | ConvertTo-Json -Depth 9 | Out-File -FilePath $outputFilePath

Write-Host "Variables data has been exported and saved to $outputFilePath"

