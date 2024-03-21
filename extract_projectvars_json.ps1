PowerShell script to extract project-specific variables from Octopus Deploy in JSON format:
 
# Replace these variables with your Octopus Deploy API key and server URL
$apiKey = "YOUR_API_KEY"
$octopusServerUrl = "YOUR_OCTOPUS_SERVER_URL"
 
# Replace this with the name of the project whose variables you want to extract
$projectName = "YOUR_PROJECT_NAME"
 
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
