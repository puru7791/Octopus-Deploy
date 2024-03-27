##Config
$OctopusAPIkey = "$env:OCTOPUS_API_KEY"   #Octopus API Key

$OctopusURL = "$env:OCTOPUS_SERVER_URL"   #Octopus URL

$variableSetName = "$env:variableSetName" #Name of the variable set

$outputFilePath = "$env:exportedVariablesSet"

$header = @{ "X-Octopus-ApiKey" = $octopusAPIKey }

##Process
$VariableSet = (Invoke-WebRequest "$OctopusURL/api/libraryvariablesets?contentType=Variables" -Headers $header).content | ConvertFrom-Json | select -ExpandProperty Items | ?{$_.name -eq $variableSetName}

$variables = (Invoke-WebRequest "$OctopusURL/$($VariableSet.Links.Variables)" -Headers $header).content | ConvertFrom-Json | select -ExpandProperty Variables

$variables | ConvertTo-Json -Depth 9 | Out-File -FilePath $outputFilePath    #<--- Collection of variables of the variable set

Write-Host "Variables data of $variableSetName has been exported and saved to $outputFilePath"
