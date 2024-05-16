function Set-OctopusVariables {
    param(
        $octopusURL = "", # Octopus Server URL
        $octopusAPIKey = "",               # API key goes here
        $projectName = "",                        # Replace with your project name
        $spaceName = "Default",                   # Replace with the name of the space you are working in
        $variablesFilePath = "$env:variableSetFilePath", # Path to JSON file containing variables
        $gitRefOrBranchName = $null               # Set this value if you are storing a plain-text variable and the project is version controlled. If no value is set, the default branch will be used.
    )

    # Defines header for API call
    $header = @{ "X-Octopus-ApiKey" = $octopusAPIKey }

    # Get space
    $space = (Invoke-RestMethod -Method Get -Uri "$octopusURL/api/spaces/all" -Headers $header) | Where-Object {$_.Name -eq $spaceName}

    # Get project
    $project = (Invoke-RestMethod -Method Get -Uri "$octopusURL/api/$($space.Id)/projects/all" -Headers $header) | Where-Object {$_.Name -eq $projectName}

    # Get project variables
    $projectVariables = Invoke-RestMethod -Method Get -Uri "$octopusURL/api/$($space.Id)/variables/$($project.VariableSetId)" -Headers $header

    if($project.IsVersionControlled -eq $true) {
        if ([string]::IsNullOrWhiteSpace($gitRefOrBranchName)) {
            $gitRefOrBranchName = $project.PersistenceSettings.DefaultBranch
            Write-Output "Using $($gitRefOrBranchName) as the gitRef for this operation."
        }
        $versionControlledVariables = Invoke-RestMethod -Method Get -Uri "$octopusURL/api/$($space.Id)/projects/$($project.Id)/$($gitRefOrBranchName)/variables" -Headers $header
    }

    # Load variables from the JSON file
    $variablesData = Get-Content -Raw -Path $variablesFilePath | ConvertFrom-Json
    $variables = $variablesData.Variables
    $scopeValues = $variablesData.ScopeValues.Environments

    foreach ($variable in $variables) {
        $scopeNames = @()
        $scopeIds = @()

        if ($variable.Scope.Environment) {
            foreach ($scopeId in $variable.Scope.Environment) {
                $environmentObj = $scopeValues | Where-Object { $_.Id -eq $scopeId }
                if ($environmentObj) {
                    $scopeIds += $environmentObj.Id
                    $scopeNames += $environmentObj.Name
                }
            }
        }

        foreach ($scopeName in $scopeNames) {
            $variableObject = @{
                Name = $variable.Name
                Value = $variable.Value
                Type = $variable.Type
                IsSensitive = $variable.IsSensitive
                Scope = @{ Environment = @($scopeIds | Where-Object { $scopeValues | Where-Object { $_.Name -eq $scopeName } }) }
            }

            # Assign the correct variables based on version-controlled project or not
            if($project.IsVersionControlled -eq $True -and $variableObject.IsSensitive -eq $False) {
                $projectVariables = $versionControlledVariables
            }

            # Check to see if variable is already present. If so, removing old version(s).
            $variablesWithSameName = $projectVariables.Variables | Where-Object {$_.Name -eq $variableObject.Name}

            if ($variablesWithSameName.Scope.Environment -eq $variableObject.Scope.Environment){
                # The existing variable with the same name is scoped to the same environment, removing it
                $projectVariables.Variables = $projectVariables.Variables | Where-Object { $_.id -ne $variablesWithSameName.id }
            }

            # Adding the new value
            $projectVariables.Variables += $variableObject
        }
    }

    # Update the collection
    if($project.IsVersionControlled -eq $True -and $variableObject.IsSensitive -eq $False) {
        Invoke-RestMethod -Method Put -Uri "$octopusURL/api/$($space.Id)/projects/$($project.Id)/$($gitRefOrBranchName)/variables" -Headers $header -Body ($projectVariables | ConvertTo-Json -Depth 10)    
    }
    else {
        Invoke-RestMethod -Method Put -Uri "$octopusURL/api/$($space.Id)/variables/$($project.VariableSetId)" -Headers $header -Body ($projectVariables | ConvertTo-Json -Depth 10)
    }
}

Set-OctopusVariables -octopusURL "https://puru1.octopus.app/" -octopusAPIKey "API-LASAU99DNWMY0WOKNGJZNE9GORXLNSAH" -projectName "First-project" -variablesFilePath "demo-variables.json" -gitRefOrBranchName $null
