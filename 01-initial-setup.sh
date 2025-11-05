#!/usr/bin/env bash

#
# 🚀 01-initial-setup.sh
#
# This script prepares the host environment for the GitLab container.
#
# ❗ PREREQUISITE:
# You MUST create the 'cicd.env' file in the '~/cicd_stack' directory
# *before* running this script. It must contain:
#
#   GITLAB_ROOT_PASSWORD="your-secure-password"
#   GMAIL_APP_PASSWORD="your-16-char-password"
#

# --- Configuration ---
CICD_DIR="$HOME/cicd_stack"
ENV_FILE="$CICD_DIR/cicd.env"
GITIGNORE_FILE="$CICD_DIR/.gitignore"
GITIGNORE_ENTRY="cicd.env"

# --- GitLab Config Paths ---
GITLAB_CONFIG_DIR="$CICD_DIR/gitlab/config"
GITLAB_TRUSTED_CERTS_DIR="$GITLAB_CONFIG_DIR/trusted-certs"
GITLAB_CONFIG_FILE="$GITLAB_CONFIG_DIR/gitlab.rb"

# --- CA Paths ---
CA_CERT_SOURCE="${HOME}/cicd_stack/ca/pki/certs/ca.pem"
CA_CERT_DEST="$GITLAB_TRUSTED_CERTS_DIR/ca.pem"


# --- Script ---

echo "🚀 Starting setup..."

# 1. 🛑 PREREQUISITE CHECK: Stop if cicd.env is missing
if [ ! -f "$ENV_FILE" ]; then
    echo "---------------------------------------------------------------"
    echo "⛔ ERROR: '$ENV_FILE' not found."
    echo "Please create this file with your passwords before running."
    echo "It must contain:"
    echo "  GITLAB_ROOT_PASSWORD=\"...\""
    echo "  GMAIL_APP_PASSWORD=\"...\""
    echo "---------------------------------------------------------------"
    exit 1
fi

# 2. Ensure the base directory exists (owned by user)
mkdir -p "$CICD_DIR"

# 3. Add cicd.env to .gitignore (owned by user)
if ! grep -q -F "$GITIGNORE_ENTRY" "$GITIGNORE_FILE" 2>/dev/null; then
    echo "Adding $GITIGNORE_ENTRY to $GITIGNORE_FILE..."
    echo "$GITIGNORE_ENTRY" >> "$GITIGNORE_FILE"
else
    echo "$GITIGNORE_ENTRY is already in $GITIGNORE_FILE. Skipping."
fi

# 4. Ensure the gitlab config directories exist (requires sudo)
echo "Ensuring GitLab config directories exist (may ask for password)..."
sudo mkdir -p "$GITLAB_CONFIG_DIR"
sudo mkdir -p "$GITLAB_TRUSTED_CERTS_DIR"

# 5. Copy the CA certificate into the trusted-certs directory (requires sudo)
if [ -f "$CA_CERT_SOURCE" ]; then
    echo "Copying CA certificate to $CA_CERT_DEST (may ask for password)..."
    sudo cp "$CA_CERT_SOURCE" "$CA_CERT_DEST"
else
    echo "⚠️ WARNING: CA certificate not found at $CA_CERT_SOURCE."
    echo "Please ensure your CA is generated before running GitLab."
fi

# 6. Create the gitlab.rb configuration file (requires sudo)
echo "Creating custom gitlab.rb configuration (may ask for password)..."

# Load the .env file variables into this script's environment
set -a # Automatically export all variables that are defined
source "$ENV_FILE"
set +a # Stop auto-exporting

# This sudo block injects the *values* from the .env file
# directly into the gitlab.rb file.
sudo bash -c "cat << EOF > $GITLAB_CONFIG_FILE
# --- Main GitLab URL ---
# This is the address all containers on 'cicd-net' will use.
external_url 'https://gitlab:10300'

# --- Custom SSL Configuration ---
nginx['enable'] = true
nginx['ssl_certificate'] = '/etc/gitlab/ssl/gitlab.crt.pem'
nginx['ssl_certificate_key'] = '/etc/gitlab/ssl/gitlab.key.pem'

# --- Disable Let's Encrypt ---
letsencrypt['enable'] = false

# --- SMTP Email (Gmail) Configuration ---
# NOTE: Update 'YOUR_GMAIL_EMAIL_HERE' with your actual Gmail address
# The password is hardcoded from the .env file during setup.
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = 'smtp.gmail.com'
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = 'YOUR_GMAIL_EMAIL_HERE'
gitlab_rails['smtp_password'] = '${GMAIL_APP_PASSWORD}'
gitlab_rails['smtp_domain'] = 'smtp.gmail.com'
gitlab_rails['smtp_authentication'] = 'login'
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = false

# --- Email From/Reply-to Settings ---
# NOTE: Update 'YOUR_GMAIL_EMAIL_HERE' and 'YOUR_DOMAIN_HERE'
gitlab_rails['gitlab_email_from'] = 'YOUR_GMAIL_EMAIL_HERE'
gitlab_rails['gitlab_email_reply_to'] = 'noreply@YOUR_DOMAIN_HERE'

# --- Set Initial Root Password ---
# The password is hardcoded from the .env file during setup.
gitlab_rails['initial_root_password'] = '${GITLAB_ROOT_PASSWORD}'

EOF"

echo "✅ Setup complete. You are now ready to run 02-create-docker.sh"