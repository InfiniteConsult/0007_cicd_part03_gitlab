import os
import ssl
import json
import urllib.request
from pathlib import Path

# --- Configuration ---
ENV_FILE_PATH = Path.home() / "cicd_stack" / "cicd.env"
GITLAB_URL = "https://gitlab:10300" # Our host-accessible URL
GROUP_NAME = "Articles" # The group we created in 5.2

# --- Standard Library .env parser ---
def load_env(env_path):
    """
    Reads a .env file and loads its variables into os.environ.
    No third-party packages needed.
    """
    print(f"Loading environment from: {env_path}")
    if not env_path.exists():
        print(f"⛔ ERROR: Environment file not found at {env_path}")
        return False

    with open(env_path, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                key = key.strip()
                value = value.strip().strip('"\'') # Remove quotes
                os.environ[key] = value
    return True

# --- Find the Group ID ---
# We must find the numeric ID for our "Articles" group
def get_group_id(group_name, token, context):
    print(f"Searching for Group ID for: {group_name}...")

    headers = {"PRIVATE-TOKEN": token}
    url = f"{GITLAB_URL}/api/v4/groups?search={group_name}"

    req = urllib.request.Request(url, headers=headers)

    try:
        with urllib.request.urlopen(req, context=context) as response:
            groups = json.loads(response.read().decode())
            if not groups:
                print(f"Error: Group '{group_name}' not found.")
                return None

            # Find the exact match
            for group in groups:
                if group['name'] == group_name:
                    print(f"Found Group ID: {group['id']}")
                    return group['id']

            print(f"Error: No exact match for '{group_name}' found.")
            return None
    except Exception as e:
        print(f"An error occurred: {e}")
        return None

# --- Create the Project ---
def create_project(group_id, project_name, token, context):
    print(f"Creating project '{project_name}' in Group ID {group_id}...")

    headers = {
        "PRIVATE-TOKEN": token,
        "Content-Type": "application/json"
    }
    url = f"{GITLAB_URL}/api/v4/projects"

    # We will create the project from our 0004 article
    payload = json.dumps({
        "name": project_name,
        "namespace_id": group_id,
        "visibility": "private",
        "initialize_with_readme": False
    }).encode('utf-8')

    req = urllib.request.Request(url, data=payload, headers=headers, method='POST')

    try:
        with urllib.request.urlopen(req, context=context) as response:
            project = json.loads(response.read().decode())
            print(f"✅ Success! Project created.")
            print(f"  ID: {project['id']}")
            print(f"  URL: {project['web_url']}")
    except Exception as e:
        print(f"An error occurred creating project: {e}")
        if hasattr(e, 'read'):
            print(f"  Response: {e.read().decode()}")

# --- Main ---
if __name__ == "__main__":
    if not load_env(ENV_FILE_PATH):
        exit(1)

    GITLAB_TOKEN = os.getenv('GITLAB_API_TOKEN')

    if not GITLAB_TOKEN:
        print("Error: GITLAB_API_TOKEN not found in cicd.env")
        exit(1)

    # This is the payoff from Article 2!
    # We just create the default context. Python will
    # automatically use the system trust store, which
    # now contains our Local CA.
    print("Creating default SSL context...")
    context = ssl.create_default_context()

    group_id = get_group_id(GROUP_NAME, GITLAB_TOKEN, context)

    if group_id:
        create_project(group_id, "0004_std_lib_http_client", GITLAB_TOKEN, context)
