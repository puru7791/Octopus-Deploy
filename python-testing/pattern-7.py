##### Test case 5
import json
import requests

def extract_and_add_variable(source_json_url, project_variable_json, variable_names):
    if source_json_url.startswith("http"):
        source_data = requests.get(source_json_url).json()
    else:
        with open(source_json_url, 'r') as f:
            source_data = json.load(f)

    with open(project_variable_json, 'r') as f:
        dest_data = json.load(f)

    dest_environment_list = dest_data["ScopeValues"]["Environments"]
    dest_environment_dict = {env["Id"]: env["Name"] for env in dest_environment_list}

    for variable_name in variable_names:
        existing_variables = [variable for variable in dest_data["Variables"] if variable["Name"] == variable_name]
        if existing_variables:
            for existing_variable in existing_variables:
                existing_variable_value = existing_variable["Value"]
                existing_variable_environment_ids = existing_variable["Scope"]["Environment"]
                
                matching_environment_names = []
                for env_id in existing_variable_environment_ids:
                    if env_id in dest_environment_dict:
                        matching_environment_names.append(dest_environment_dict[env_id])

                existing_variable_environment_names = ", ".join(matching_environment_names)
                print(f"Variable '{variable_name}' already exists in the destination '{project_variable_json}' file with Value: {existing_variable_value} and Environments: {existing_variable_environment_names}")
                break  # Stop the loop when the matching environment is found

            continue
        
        print(f"Adding the '{variable_name}' Variable property block to the destination '{project_variable_json}' file")
        extracted_data = []
        for variable in source_data["Variables"]:
            if variable.get("Name") == variable_name:
                extracted_data.append(variable)

        dest_data["Variables"].extend(extracted_data)

    with open(project_variable_json, 'w') as f:
        json.dump(dest_data, f, indent=2)

# Read source data from file
with open("python-testing\global_ref.json", 'r') as f:
    source_data = json.load(f)

# Process each source data entry
for data_entry in source_data:
    source_json_url = data_entry["global_variable_json_url"]
    variable_names = data_entry["variable_names"]
    project_variable_json = "demo-variables.json"  # Assuming same destination JSON file for all sources

    # Call function to extract and add variables to destination JSON
    if data_entry.get("copy_all"):
        all_variables = requests.get(source_json_url).json()
        variable_names.extend(variable["Name"] for variable in all_variables)

    extract_and_add_variable(source_json_url.strip(), project_variable_json, variable_names)
