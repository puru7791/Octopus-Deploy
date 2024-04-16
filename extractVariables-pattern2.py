import json

def extract_and_add_variable(source_json, dest_json, variable_names):
    with open(source_json, 'r') as f:
        source_data = json.load(f)

    with open(dest_json, 'r') as f:
        dest_data = json.load(f)

    for variable_name in variable_names:
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

# Prompt the user to enter the list of variable names
variable_names = input("Enter the list of variable names to extract (comma-separated): ").split(",")

# Call function to extract and add variables to destination JSON
extract_and_add_variable(source_json_file, dest_json_file, variable_names)
