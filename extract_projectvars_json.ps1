#PowerShell script to extract project-specific variables from Octopus Deploy in JSON format:
 
# Replace these variables with your Octopus Deploy API key and server URL
$apiKey = "$env:OCTOPUS_API_KEY"
$octopusServerUrl = "$env:OCTOPUS_SERVER_URL"
 
# Replace this with the name of the project whose variables you want to extract
$projectName = "$env:ProjectName"
 
# Base64 encode the API key
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($apiKey)"))
 
# Define the API endpoint to retrieve project variables
$uri = "$octopusServerUrl/api/variables/$projectName"
 
# Make a GET request to the Octopus Deploy API
$response = Invoke-RestMethod -Uri $uri -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}
 
# Output the variables in JSON format
$jsonOutput = $response | ConvertTo-Json
 
# Output the JSON
$jsonOutput
