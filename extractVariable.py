import json

def extract_and_add_variable(source_json, dest_json, variable_name):
    with open(source_json, 'r') as f:
        source_data = json.load(f)

    with open(dest_json, 'r') as f:
        dest_data = json.load(f)

    extracted_data = []
    for variable in source_data["Variables"]:
        if variable.get("Name") == variable_name:
            extracted_data.append(variable)

    dest_data["Variables"].extend(extracted_data)

    with open(dest_json, 'w') as f:
        json.dump(dest_data, f, indent=2)

# Define file paths
source_json_file = "Octopus-Deploy/exportedVariableSet-1.json"
dest_json_file = "demo-variables.json"
variable_name_to_extract = "AppSettings.var1"

# Call function to extract and add variable to destination JSON
extract_and_add_variable(source_json_file, dest_json_file, variable_name_to_extract)
