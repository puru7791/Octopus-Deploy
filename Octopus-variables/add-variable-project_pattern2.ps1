function Set-OctopusVariable {
    param(
        $octopusURL = "https://xxx.octopus.app/", # Octopus Server URL
        $octopusAPIKey = "API-xxx",               # API key goes here
        $projectName = "",                        # Replace with your project name
        $spaceName = "Default",                   # Replace with the name of the space you are working in
        $environments = @(),                      # Array of environment names
        $varName = "",                            # Replace with the name of the variable
        $varValue = ""                            # Replace with the value of the variable
    )

    Write-Output "Starting to process variable $varName"

    # Defines header for API call
    $header = @{
        "X-Octopus-ApiKey" = $octopusAPIKey
        "Content-Type" = "application/json"
    }

    # Get space
    $space = (Invoke-RestMethod -Method Get -Uri "$octopusURL/api/spaces/all" -Headers $header) | Where-Object {$_.Name -eq $spaceName}
    Write-Output "Space ID: $($space.Id)"

    # Get project
    $project = (Invoke-RestMethod -Method Get -Uri "$octopusURL/api/$($space.Id)/projects/all" -Headers $header) | Where-Object {$_.Name -eq $projectName}
    Write-Output "Project ID: $($project.Id)"

    # Get project variables
    $projectVariables = Invoke-RestMethod -Method Get -Uri "$octopusURL/api/$($space.Id)/variables/$($project.VariableSetId)" -Headers $header
    Write-Output "Retrieved project variables"

    # Get environment IDs to scope to
    $environmentIds = @()
    foreach ($envName in $environments) {
        Write-Output "Attempting to find environment: $envName"
        $environmentObj = $projectVariables.ScopeValues.Environments | Where-Object { $_.Name -eq $envName } | Select-Object -First 1
        if ($environmentObj -ne $null) {
            Write-Output "Environment $envName found with ID: $($environmentObj.Id)"
            $environmentIds += $environmentObj.Id
        } else {
            Write-Output "Environment $envName not found"
        }
    }

    # Define values for variable
    $variable = [PSCustomObject]@{
        Name = $varName
        Value = $varValue
        Type = "String"
        IsSensitive = $false
        Scope = @{
            Environment = $environmentIds
        }
    }

    Write-Output "Variable details prepared"

    # Remove existing variables with the same name and scope
    foreach ($envId in $environmentIds) {
        $existingVar = $projectVariables.Variables | Where-Object { 
            $_.Name -eq $varName -and ($_.Scope.Environment -contains $envId)
        }
        $projectVariables.Variables = $projectVariables.Variables | Where-Object { $_.Id -notin $existingVar.Id }
    }

    # Ensure project variables are treated as an array
    $projectVariables.Variables = @($projectVariables.Variables)

    # Add the new value to the variables collection
    $projectVariables.Variables += $variable
    Write-Output "Added variable $varName to the project variables"

    # Update the collection
    Invoke-RestMethod -Method Put -Uri "$octopusURL/api/$($space.Id)/variables/$($project.VariableSetId)" -Headers $header -Body ($projectVariables | ConvertTo-Json -Depth 10)
    Write-Output "Updated project variables on the server"
}

function Set-OctopusVariablesFromJson {
    param(
        $jsonFilePath,                            # Path to the JSON file
        $octopusURL = "https://xxx.octopus.app/", # Octopus Server URL
        $octopusAPIKey = "API-xxx",               # API key goes here
        $projectName = "",                        # Replace with your project name
        $spaceName = "Default"                    # Replace with the name of the space you are working in
    )

    Write-Output "Loading variables from JSON file: $jsonFilePath"

    # Read JSON file
    $jsonContent = Get-Content -Path $jsonFilePath -Raw | ConvertFrom-Json

    Write-Output "Loaded variables JSON content"

    # Iterate through each variable in the JSON file
    foreach ($variable in $jsonContent.Variables) {
        Write-Output "Processing variable: $($variable.Name)"
        $environments = @()
        if ($variable.Environment -is [string]) {
            $environments += $variable.Environment
        } elseif ($variable.Environment -is [array]) {
            $environments += $variable.Environment
        }
        
        Set-OctopusVariable -octopusURL $octopusURL `
                            -octopusAPIKey $octopusAPIKey `
                            -projectName $projectName `
                            -spaceName $spaceName `
                            -environments $environments `
                            -varName $variable.Name `
                            -varValue $variable.Value
    }
    Write-Output "Completed processing variables from JSON file"
}

# Example call to the function
Set-OctopusVariablesFromJson -jsonFilePath "path\to\variables.json" -octopusURL "https://xxx.octopus.app/" -octopusAPIKey "API-xxx" -projectName "hello_world"
