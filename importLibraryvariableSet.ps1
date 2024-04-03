$ErrorActionPreference = "Stop";
# Define the Octopus server URL and API key
$octopusURL = "$env:OCTOPUS_SERVER_URL"
$octopusAPIKey = "$env:OCTOPUS_API_KEY"
$header = @{ "X-Octopus-ApiKey" = $octopusAPIKey }
# Specify the Space to search in
$spaceName = "$env:SpaceName"

# Define the name of the library variable set
$libraryVariableSetName = "$env:libraryVariableSetName"

# Load JSON file from the local directory
$jsonFilePath = "$env:variableSetjsonFilePath"
$jsonVariables = Get-Content $jsonFilePath | ConvertFrom-Json

#Get space Name
$space = (Invoke-RestMethod -Method Get -Uri "$octopusURL/api/spaces/all" -Headers $header) | Where-Object {$_.Name -eq $spaceName}
Write-Host "found the Space ID of $spaceName is $($space.Id)"

Write-Host "Looking for library variable set '$libraryVariableSetName'"
$LibraryvariableSets = (Invoke-RestMethod -Method Get -Uri "$octopusURL/api/$($space.Id)/libraryvariablesets?contentType=Variables" -Headers $header)
$LibraryVariableSet = $LibraryVariableSets.Items | Where-Object { $_.Name -eq $libraryVariableSetName }

if ($null -eq $LibraryVariableSet) {
    Write-Warning "Library variable set not found with name '$libraryVariableSetName'."
    exit
}

# Get existing variables from the Octopus library variable set

$LibraryVariableSetVariables = (Invoke-RestMethod -Method Get -Uri "$octopusURL/api/$($Space.Id)/variables/$($LibraryVariableSet.VariableSetId)" -Headers $header)

# Iterate through each variable in the JSON data
foreach ($variable in $jsonVariables) {
    $variableName = $variable.Name
    $variableValue = $variable.Value

    # Check if the variable already exists in the Octopus library variable set
    for($i=0; $i -lt $LibraryVariableSetVariables.Variables.Length; $i++) {
        $existingVariable = $LibraryVariableSetVariables.Variables[$i];
        if($existingVariable.Name -eq $VariableName) {
            Write-Host "Found existing variable"
            if($existingVariable.Value -eq $VariableValue){
                Write-Host "Value of variable '$variableName' is already up to date."
            }
            else {
                Write-Host "updating its value $existingVariable.Name"
                $existingVariable.Value = $VariableValue
            }
            continue
        }
		
        
    }
    # # Add the new variable to the Octopus library variable set
    # $newVariable = @{
    #     Name = $variableName
    #     Value = $variableValue
    # }

    # $existingVariables.Variables += $newVariable
    # Write-Host "Added new variable '$variableName' to the Octopus library variable set."
}

# Update the Octopus library variable set with any new variables
$UpdatedLibraryVariableSet = Invoke-RestMethod -Uri "$octopusURL/api/$($Space.Id)/variables/$($LibraryVariableSetVariables.Id)" -Method Put -Headers $header -Body ($LibraryVariableSetVariables | ConvertTo-Json -Depth 10)
