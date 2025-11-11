# Chapter 1: The "Why" - Rejecting the SaaS "Pain Point"

## 1.1 Goal: Building the "Central Library"

We have successfully built our "city" foundations. We have a secure "Control Center" (DooD), private "roads" (`cicd-net`), persistent "foundations" (our hybrid volume strategy), and a trusted "security office" (our Local CA).

We are *ready* to build, but we have no "blueprints." Our code—the very thing we want to build, test, and deploy—has no home.

This is the "chaos" pain point. Without a **Source Code Manager (SCM)**, our projects live in a state of entropy: `project-final-v2.zip`, `project-final-v3-JOHNS-EDITS.zip`. It's impossible to know who changed what or which version is the "real" one.

We will solve this by deploying **GitLab Community Edition (CE)**. This will be the first "skyscraper" in our city and will serve as the "Central Library"—the single source of truth for all our code.

---

## 1.2 The "First Principles" Question: Why Not Just Use GitHub.com?

Before we run a single command, we must address the obvious "easy button" solution. Why go through the trouble of deploying a complex, self-hosted SCM when `GitHub.com` exists?

The answer is that `GitHub.com` is a **SaaS (Software-as-a-Service)** solution. It's a "black box" that introduces "pain points" that are in direct conflict with the "first principles" architecture we have so carefully built.

> **The Analogy:** We are building a private, secure, self-contained "city." `GitHub.com` is the *public library* located across town, on the other side of the ocean.
>
> To build our "factories" (Jenkins) and "warehouses" (Artifactory) *inside* our city walls and then have them rely on a library on another continent is an architectural flaw. It creates dependencies, security risks, and latency.
>
> The *only* architecturally-sound solution is to build our *own* "Central Library" *inside* our city walls, on our private "road network."

---

## 1.3 Deconstructing the SaaS "Pain Points"

Relying on an external `GitHub.com` fails our "first principles" test by creating three critical "pain points."

### 1. The Network Isolation Pain Point

This is the most immediate problem. `GitHub.com` lives on the public internet. Our entire CI/CD stack lives *inside* our private, isolated **`cicd-net`**.

This breaks the integration. How can `GitHub.com` (on the public internet) send a webhook to `https://jenkins.cicd.local:8443` (a private hostname on our `cicd-net`)? It can't. It's like shouting from the public library and expecting our "factory foreman" (Jenkins) to hear it inside our walled city.

To make this work, we would have to punch dangerous holes in our host firewall, set up complex reverse proxies, and expose our internal Jenkins server to the entire internet—a massive security risk.

### 2. The Data Sovereignty & Control Pain Point

When you use `GitHub.com`, you are a **"tenant"** on Microsoft's platform. Your source code, your intellectual property, and your project's metadata are all stored on their servers.

By self-hosting GitLab CE, we become the **"landlord."** We have 100% control over our own data. Our code lives on our `gitlab-data` volume, secured by our Local CA, and is never exposed to a third party.

### 3. The Cost & Feature "Pain Point"

The "free" tier on SaaS platforms is feature-gated to push you to paid plans.

* **CI/CD "Minutes":** Public CI services (like GitHub Actions) charge you for compute time, often after a small free quota. This creates a "pain point" of unpredictable costs and limits how often you can build.
* **"Protected Branches":** This is the most critical pedagogical "gotcha." On `GitHub.com`, the ability to "protect" a branch (e.g., to force all changes to go through a Merge Request) is a **paid feature**.

This breaks our workflow. The entire *point* of our CI pipeline is to run on Merge Requests. By self-hosting **GitLab CE**, this critical "Protected Branch" feature is **100% free**.

---

## 1.4 The Solution: Our Self-Hosted Foundation

A self-hosted GitLab CE instance is the only choice that respects our architecture. It solves all three "pain points":

1.  It will live **inside** our `cicd-net`, allowing it to talk to `jenkins` and our other tools securely.
2.  It gives us **100% data sovereignty**.
3.  It gives us critical enterprise features like "Protected Branches" for **free**.

We will now build our "Central Library" on the "foundation" we prepared in Articles 1 and 2.

# Chapter 2: The "What" - Core SCM & GitLab Concepts

## 2.1. The "First Principles" of Source Code Management

To understand *why* GitLab is the "Central Library" for our "city," we must first deconstruct the problem it solves. This isn't just a GitLab concept; it's the fundamental "pain point" of all software development: **managing change over time.**

### The "Chaos" (No SCM)

Without an SCM, we live in a world of chaos. We use file naming conventions that are, in effect, a cry for help:
* `project-v1.zip`
* `project-v2-final.zip`
* `project-v2-final-REVISED.zip`
* `project-v2-final-JOHNS-EDITS.zip`

This "shared folder" model has no "first principles." There is no history, no accountability, and no way to safely merge changes from two developers.

### The "Old" Solution: Centralized SCM (e.g., Subversion)

The first generation of tools solved this by introducing a "central server." These are **Centralized Version Control Systems (CVCS)**. The most famous example is **Subversion (SVN)**.

> **The Analogy:** An SVN server is a **"Central Library" with a single, strict "Librarian."**
>
> To edit a file, you must "check it out" from the librarian. While you have it, no one else can edit it (a "lock"). When you are done, you "check it in," and the librarian saves the new version.

This was a massive improvement, but it created a new, critical "pain point":

1.  **It's a Single Point of Failure:** If the "Central Library" (the SVN server) crashes or the network goes down, *all development stops*. No one can "check in" or "check out" code.
2.  **It's Not Truly "Versioned":** Your local machine only has the *one version* you checked out. You do not have the *entire history* of the project.

### The "Modern" Solution: Distributed SCM (i.e., Git)

**Git** is the "first principles" solution to the "pain points" of SVN. It is a **Distributed Version Control System (DVCS)**.

This is the most critical concept to understand:

> **The Analogy:** With Git, you don't just "check out a book" from the library. You **"clone" the entire library.**
>
> Every single developer on your team has a full, 1-to-1 copy of the *entire project and its complete history* on their local machine.

This solves all of SVN's "pain points":
1.  **There is No Single Point of Failure:** If the "Central Library" server (which we will build with GitLab) goes down, you don't even notice. You can still browse the full history, create new commits, and switch branches, all on your local machine.
2.  **It's Blazing Fast:** Since the entire "library" (the `.git` directory) is on your local disk, checking history or creating a branch is instantaneous.

### The "First Principles" of Git (The Commands)

This "distributed" model is what gives us the core "first principle" concepts that GitLab is built on top of:

* **Repository (Repo):** This is the "library" itself—the project folder containing all your code and the hidden `.git` directory (the "ledger").
    * `git init` (Creates a new, empty "library")
    * `git clone <url>` (Copies an *entire existing library* to your machine)

* **Commit:** This is a "snapshot" or a "save point" in your local library. It's a permanent record of a change.
    * `git add .` (Stages your changes for the snapshot)
    * `git commit -m "My change description"` (Creates the permanent snapshot in your local history)

* **Branch:** This is an "independent line of development." It's a "copy" of the "master blueprint" that you can safely work on without disturbing the main, stable version.
    * `git checkout -b my-new-feature` (Creates a new branch *and* switches to it)
    * `git checkout main` (Switches back to the main, stable branch)

This is the "engine" that runs *locally*. This leaves one final "pain point": if everyone has their own "copy of the library," how does everyone *sync up* their changes?

That is the role of **GitLab**. It is the "Central Library" that we *designate* as the "single source of truth." It's the "public square" where all developers bring their local changes (`git push`) and share them with the team (`git pull`).

## 2.2. The "Collaboration" Principle: The Merge Request

We have established the "first principle" of Git: everyone has a *local* "copy of the library" (`.git` directory) and can make *local* "snapshots" (`git commit`).

This leaves us with the final and most important operational "pain point": **How do we safely merge all these individual, distributed changes back into the "Central Library" (GitLab)?**

The "easy" or "naive" way is for every developer to simply push their changes directly to the `main` branch:
`git push origin main`

This is architecturally reckless and creates a new "pain point" of **workflow chaos**.

> **The Analogy:** Allowing direct pushes to `main` is like letting *any* engineer walk into the "Central Library" at *any* time and scribble directly on the **master blueprint**.
>
> What if their change is wrong? What if it's incomplete? What if two engineers try to edit the same page at the same time? The "master blueprint" becomes a mess of conflicting, untested, and unverified changes. This breaks the build for everyone and defeats the purpose of having a "single source of truth."

---

### The "First Principles" Solution: The Merge Request

To solve this "collaboration pain point," we introduce the **Merge Request (MR)**. (This is known as a "Pull Request" or "PR" on GitHub, but we will use GitLab's terminology).

A Merge Request is the "first principle" of professional, team-based collaboration. It is a formal *process* for managing change, not just a *command*.

The workflow is as follows:

1.  A developer **never** works on the `main` branch.
2.  They create a new **branch** (their "private copy" of the blueprint) (e.g., `git checkout -b feature/add-login-button`).
3.  They make all their **commits** safely on this private branch.
4.  When their work is complete, they `git push` their *branch* (not `main`) to GitLab.
5.  Finally, they go to the GitLab UI and open a **Merge Request**.

> **The Analogy:** A Merge Request is a **"formal proposal"** submitted to the "head librarian" (the project maintainers).
>
> You are not *making* the change to the master blueprint. You are *proposing* it. You are saying:
>
> "I have finished my work on my private copy (my 'feature' branch). Here is a summary of my changes. Please review them. If you and the rest of the team approve, please *merge* my proposal into the master blueprint ('main')."

This simple process changes everything. It creates a central, auditable "lobby" for every proposed change. It's the place where your team can:

* **Review the Code:** Leave comments, suggest improvements, and ensure quality.
* **Discuss the Change:** Debate the solution and its impact.
* **Verify the Solution:** This is the most critical part.

This **Merge Request** is the **key trigger** for our entire CI/CD stack. It is the "starting gun" for our whole automation pipeline. The moment an MR is opened, our "Central Library" (GitLab) will send a signal (a webhook) to our "Factory Foreman" (Jenkins), which will automatically run all the builds, tests, and quality scans.

This is the *entire reason* we are building our stack: to automate the *verification* of these "proposals" *before* they are ever merged into our "master blueprint."

## 2.3. The "Permissions Pain Point" (GitHub vs. GitLab)

We have our "Central Library" (GitLab) and a formal "proposal" process (Merge Requests). This introduces the final core concept: **access control**. Who is allowed in the library, and what are they allowed to do?

This is a massive "pain point" in any large organization. If you have 100 developers and 50 projects, how do you manage their permissions? Manually adding 100 users to 50 different projects (5,000 operations) is not just tedious; it's an auditing and security nightmare.

This is where the architectural differences between SCM platforms become critical.

* **The GitHub "Organization" Model:** GitHub's solution is the **"Organization."** This is a good model that gathers all your projects under one "roof." You can then create "Teams" (e.g., "Frontend Developers," "Backend Developers") and grant those *teams* access to individual repositories. This is a big improvement, but the structure is relatively flat. You still have to manually manage the connections between many teams and many repositories.

* **The GitLab "Group" Model (The Architectural Solution):** GitLab solves this "permissions pain point" with a more powerful, **hierarchical namespace**.

> **The Analogy:** A GitHub "Organization" is like a *single, large library building*. You create "teams" (like "History Department") and give them keys to specific rooms (repositories).
>
> A GitLab **"Group"** is like an entire **"University Campus."**

This is the key distinction. A GitLab "Group" (e.g., "College of Engineering") is a container that can hold both:
1.  **Projects** (e.g., the "Robotics Lab Project")
2.  **Sub-Groups** (e.g., the entire "Computer Science Department," which *itself* has its own projects)

The architectural advantage here is **permission inheritance**.

When you hire a new developer, you don't give them 50 different keys. You simply add their user account to the "College of Engineering" **Group** *one time* and assign them the "Developer" role.

By inheritance, they *automatically* get "Developer" access to:
* The "Robotics Lab Project."
* The *entire* "Computer Science Department" sub-group.
* *Every single project* inside the "Computer Science Department."

This hierarchical "Group" model is a far superior architectural solution for managing a complex organization, and it's a core reason we have chosen GitLab as our "Central Library's" architecture. We will use this "Group" feature to organize all the projects for our new "city."

# Chapter 3: Action Plan (Part 1) — The "Blueprint First" Strategy

## 3.1. Prerequisite: The `cicd.env` File

Before we run a single script, we must perform our one and only manual setup step. We need to provide the secrets that our setup script will "bake" into the GitLab configuration.

We will create a file named **`cicd.env`** inside our project's `~/cicd_stack` directory. This file is **not** used by Docker. It is a prerequisite that is read *only* by our `01-initial-setup.sh` script. Our setup script is smart enough to add this filename to `.gitignore` automatically, ensuring we never accidentally commit our private passwords.

On your host machine, create this file. You can use `nano` or any text editor:

```bash
nano ~/cicd_stack/cicd.env
```

Add the following two lines. It is **critical** that you replace the placeholder values with your real credentials.

```ini
GITLAB_ROOT_PASSWORD="your-secure-password-here"
GMAIL_APP_PASSWORD="your-16-char-password-here"
```

> **A Note on Passwords:**
>
>   * **`GITLAB_ROOT_PASSWORD`**: This will become the password for the `root` administrator account. Make it strong and memorable.
>   * **`GMAIL_APP_PASSWORD`**: This is **not** your regular Gmail password. It is a 16-character "App Password" you must generate from your Google Account security settings. (We will walk through the exact UI steps for this in Chapter 5, but it must be generated for this script to work).

Once this file is saved, you have completed the only manual prerequisite. Our setup script will handle everything else.

## 3.2. The "First Run" Conflict (Our Key Discovery)

With our secrets file in place, we were ready to build our configuration. Our goal was to provide all configuration *before* the container started. This led us to what *should* have been a simple, two-part setup:

1.  **For SSL/SMTP:** Write a custom `gitlab.rb` file and bind-mount it to `/etc/gitlab`.
2.  **For the Password:** Securely pass the `GITLAB_ROOT_PASSWORD` using the `--env-file` flag in our `docker run` command.

This logical approach led us to a critical failure and our most important discovery. When we ran the container with **both** the bind-mounted `gitlab.rb` *and* the `--env-file` flag, the container entered a "confused" state.

This is the conflict:
* The container started successfully.
* NGINX read our `gitlab.rb` and loaded our SSL certificates.
* But the "first-run" password logic **failed silently**.
* The password from our `--env-file` was **ignored**.
* The container **did not** generate a random password, because it assumed our environment variable would work.

We were left with a perfectly-secured, SSL-enabled container that had no `root` password. The login page would just fail indefinitely.

We discovered that the presence of the **`--env-file`** flag, when used *in combination with* a pre-populated `/etc/gitlab` volume, breaks the container's "first-run" password logic.

This discovery was the key. We couldn't trust the container to manage its environment and our config file at the same time. We had to choose one.

## 3.3. The Solution: "Baking" Credentials

This discovery led us to our final, robust solution. Since the container cannot be trusted to handle both an environment file and a pre-configured `gitlab.rb` file, we will remove the source of the conflict: **we will not use the `--env-file` flag at all.**

Instead, we will create a master "blueprint" on our host *before* the container ever runs. This blueprint (`gitlab.rb`) will contain **everything** the container needs to know: our SSL paths, our SMTP settings, and, most importantly, the administrator password.

We will accomplish this using our **`01-initial-setup.sh`** script. This script will act as our "architect," performing a clever "bake-in" process:

1.  It will first read our `cicd.env` file on the host, loading the `GITLAB_ROOT_PASSWORD` and `GMAIL_APP_PASSWORD` into its own environment.
2.  It will then programmatically "bake" (i.e., hardcode) the *values* of these variables directly into the text of the `gitlab.rb` file it generates.

When the GitLab container starts, it will be completely unaware of our `cicd.env` file. It will simply see a `gitlab.rb` file with lines like:

```ruby
# (This is what the container will see)
gitlab_rails['initial_root_password'] = 'MySuperSecurePassword123'
gitlab_rails['smtp_password'] = 'ab12cd34ef56gh78'
```

This bypasses the container's broken "first-run" logic entirely. The container's setup script will read this hardcoded value from `gitlab.rb` and use it to correctly initialize the database.

While hardcoding secrets in a configuration file is generally not ideal, it is the only reliable and repeatable method to solve this specific "first-run" conflict caused by the GitLab Docker image. This "Blueprint First" strategy gives us a single, complete, and fully-configured blueprint to hand off to our deployment script.

## 3.4. The "Architect" Script (`01-initial-setup.sh`)

This is our "architect" script. Its sole purpose is to run on the host machine and prepare the *entire* configuration "blueprint" (`gitlab.rb`) and "site" (the required directories) *before* the container is ever created. It performs all the preparation we've discussed: checking prerequisites, creating directories, solving our CA trust issue, and "baking" our secrets.

Here is the complete script.

```bash
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
external_url 'https://gitlab.cicd.local:10300'

# --- Custom SSL Configuration ---
nginx['enable'] = true
nginx['ssl_certificate'] = '/etc/gitlab/ssl/gitlab.cicd.local.crt.pem'
nginx['ssl_certificate_key'] = '/etc/gitlab/ssl/gitlab.cicd.local.key.pem'

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
```

-----

## 3.5. Deconstruction of `01-initial-setup.sh`

This script is dense, but every step is a deliberate solution to a problem we uncovered. Let's deconstruct it.

* **Step 1: Prerequisite Check**: The script begins with a critical safety check. It ensures the `cicd.env` file we created in 3.1 actually exists. If it doesn't, the script immediately exits with a helpful error message. This prevents us from ever running a misconfigured setup.

* **Steps 2 & 3: Housekeeping**: These steps create the base `~/cicd_stack` directory and add our secret `cicd.env` file to `.gitignore` to prevent us from ever accidentally committing it.

* **Steps 4 & 5: Directory Scaffolding & CA Trust**: This is where we see the first piece of our proactive strategy. The script creates the `gitlab/config` and, crucially, the **`gitlab/config/trusted-certs`** directories. It then immediately copies our `ca.pem` (from Article 2) *into* this `trusted-certs` folder.

  * **This single step solves the "Outbound Trust" problem before it ever begins.** When GitLab starts for the first time, its `reconfigure` script will see our CA certificate already in place and will automatically build its trust store, adding our CA. It will then be able to send secure webhooks to `https://jenkins.cicd.local` or talk to other internal, SSL-secured services without a single SSL error. No second `reconfigure` is ever needed.

* **Step 6: The "Bake-in"**: This is the most important part of the script and the core of our solution.

  1.  **`set -a / source "$ENV_FILE" / set +a`**: This triplet of commands loads our secrets. `source` "runs" the `cicd.env` file, which sets the `GITLAB_ROOT_PASSWORD` and `GMAIL_APP_PASSWORD` variables within the script's environment.
  2.  **`sudo bash -c "cat << EOF > ..."`**: This is the "bake-in" operation. We use `sudo` to gain root privileges, which are necessary to write into the `gitlab/config` directory (as `sudo` created it). The `cat << EOF > $GITLAB_CONFIG_FILE` command writes a "here document" (all the text until the final `EOF`) into our `gitlab.rb` file.
  3.  **Variable Expansion**: Because we `source`'d the variables first, the shell *expands* them *before* `sudo` ever runs. This means the line `gitlab_rails['initial_root_password'] = '${GITLAB_ROOT_PASSWORD}'` becomes `gitlab_rails['initial_root_password'] = 'MySuperSecurePassword123'` *inside* the final file.

-----

## 3.6. Deconstruction of the "Baked" `gitlab.rb`

The `gitlab.rb` file generated by our script is the master blueprint for the entire container. Let's analyze each block:

* **`external_url 'https://gitlab.cicd.local:10300'`**
  This is arguably the most critical setting. It tells GitLab what its "public" URL is. Because all our CI/CD services (like Jenkins, SonarQube, and our dev-container) live on the same `cicd-net`, they will all be able to find and access this container using its internal DNS name, `gitlab.cicd.local`. We match the port to the host port to prevent browser issues stemming from the split-horizon DNS problem.

* **`nginx['...']` and `letsencrypt['...']`**
  This block tells GitLab's built-in Nginx web server to *disable* its default Let's Encrypt integration (`letsencrypt['enable'] = false`). Instead, we explicitly point it to the "passports" (our custom SSL certificate and key from Article 2) that we will be mounting into the `/etc/gitlab/ssl/` directory.

* **`gitlab_rails['smtp_...']`**
  This is our full SMTP configuration for sending notification emails via Gmail. It sets the server, port, and authentication. Most importantly, the line `gitlab_rails['smtp_password'] = '${GMAIL_APP_PASSWORD}'` is where the 16-character App Password (which we "baked-in") is placed, allowing GitLab to authenticate with Google. You will still need to edit this file one time to replace `YOUR_GMAIL_EMAIL_HERE` with your actual email address.

* **`gitlab_rails['initial_root_password'] = '${GITLAB_ROOT_PASSWORD}'`**
  This is the **solution to our entire login problem**. By "baking" the password from our `cicd.env` file directly into this line, we force GitLab's "first-run" database script to use *our* password. It bypasses all the broken logic, never generates a random password, and ensures that when the container is ready, we can log in with the exact credentials we intended.

# Chapter 4: Action Plan (Part 2) — Deployment & First Login

With our "architect" script (`01-initial-setup.sh`) having perfectly prepared the host environment, our "blueprint" (`gitlab.rb`) is now complete, with all our configurations and secrets "baked" in.

The hard part is over. All that's left is to bring in the "construction crew" and build the skyscraper. This second script is beautifully simple, as all the complex logic now lives in the configuration file we just built.

## 4.1. The "Construction" Script (`02-create-docker.sh`)

This script's only job is to run the `docker run` command. It takes our prepared config directory, our SSL certificates, and our persistent volumes and assembles them into a single, running container.

Here is the complete `02-create-docker.sh` script:

```bash
#!/usr/bin/env bash

# This script launches the GitLab container with all
# the networking, volumes, and security settings.

echo "🚀 Starting GitLab container..."

docker run -d \
  --name gitlab \
  --restart always \
  --hostname gitlab.cicd.local \
  --network cicd-net \
  --publish 127.0.0.1:10300:443 \
  --publish 127.0.0.1:10301:22 \
  --volume gitlab-data:/var/opt/gitlab \
  --volume gitlab-logs:/var/log/gitlab \
  --volume "${HOME}/cicd_stack/gitlab/config":/etc/gitlab \
  --volume "${HOME}/cicd_stack/ca/pki/services/gitlab.cicd.local":/etc/gitlab/ssl:ro \
  --shm-size 256m \
  gitlab/gitlab-ce:latest

echo "✅ GitLab container is starting."
echo "Monitor its progress with: docker logs -f gitlab"
```

-----

## 4.2. Deconstruction of the `docker run` Command

Every single flag in this command is a deliberate architectural decision, connecting back to the foundations we laid in Articles 1 and 2.

* **`--network cicd-net` & `--hostname gitlab.cicd.local`**: This is the payoff from Article 1. We connect our "skyscraper" to our private "city road network" (`cicd-net`) and give it an internal DNS name (`gitlab`). This is what will allow our dev-container (and later, Jenkins) to find it by simply using the address `https://gitlab.cicd.local`.

* **`--publish 127.0.0.1:10300:443` & `--publish 127.0.0.1:10301:22`**: This is our port mapping scheme.

  * It exposes the container's internal HTTPS (443) and SSH (22) ports to `10300` and `10301` on our host.
  * Critically, it binds **only to `127.0.0.1` (localhost)**. This is a key security choice. It means our GitLab instance is *not* exposed to our local LAN (e.g., your office Wi-Fi). It is only accessible from your host machine.

* **`--volume gitlab-data:/var/opt/gitlab` & `--volume gitlab-logs:/var/log/gitlab`**: This is our "storage locker" persistence strategy from Article 1. We are mounting our pre-made named volumes to store all of GitLab's opaque, internal data (like its database, repositories, and logs).

* **`--volume "${HOME}/cicd_stack/gitlab/config":/etc/gitlab`**: This is the **grand payoff** of our entire "Blueprint First" strategy. We are mounting our *fully-configured* host directory (which contains our baked `gitlab.rb` and `trusted-certs` folder) directly into the container.

* **`--volume "${HOME}/cicd_stack/ca/pki/services/gitlab.cicd.local":/etc/gitlab/ssl:ro`**: This is the payoff from Article 2. We mount our `gitlab` "passport" (its SSL certificate and key) into the container in `ro` (read-only) mode for security.

* **`--shm-size 256m`**: This is a performance optimization. GitLab's internal services use shared memory, and the Docker default is too small (64m), which can cause random crashes. We explicitly give it more memory to ensure stability.

* **The Missing Flag: `--env-file`**
  The most important part of this command is what's *missing*. We are **intentionally not using `--env-file`**. By "baking" our secrets directly into `gitlab.rb`, we have eliminated the source of our "first-run" conflict, leading to a much cleaner and more reliable deployment.

-----

## 4.3. The First Run: "Reconfiguring..."

Now, it's time to launch.

The workflow is simple:

1.  Ensure you have created and edited your `~/cicd_stack/cicd.env` file.
2.  Run your setup script: `./01-initial-setup.sh`
3.  Run your deployment script: `./02-create-docker.sh`

As soon as you run the second script, you must be patient. GitLab is a very large application. On first boot, it will run its internal `reconfigure` script to apply all the settings from our `gitlab.rb` file, build its database, and start all its services.

This process can take **3 to 5 minutes**.

You can (and should) watch this process in real-time by running:

```bash
docker logs -f gitlab
```

You will see a massive flood of text as it configures all its components. You will know it is finished when the log messages slow down and you see "Chef Client finished" messages, followed by the services (Puma, Sidekiq, etc.) starting up. Do not attempt to log in until this process is complete.

## 4.4. Verification: The First Login

Once the logs have settled, open your web browser on your host machine and navigate to the `localhost` port we published:

**`https://127.0.0.1:10300`**

Thanks to the foundational work we did in Article 2—where we imported our Local CA's root certificate into our host machine's system trust store—your browser will greet you with a **secure lock icon**. There will be no security warnings. Your browser recognizes and trusts the `gitlab` certificate because it was signed by our now-trusted Certificate Authority.

You will see the GitLab login page.

Now, for the moment of truth. Log in using the credentials **you** defined in your `cicd.env` file:

* **Username:** `root`
* **Password:** (The `GITLAB_ROOT_PASSWORD` value you set)

Because we "baked" this password directly into the `gitlab.rb` file, it will work on the very first try.

It is advisable to change the root password by clicking on the root user's avatar, clicking Preferences and navigating to the Password tab.

### Verification (Curls)

Finally, let's run our "proof of success" checks from our terminals.

* **From your Host terminal:**

  ```bash
  curl https://127.0.0.1:10300
  ```

* **From your dev-container terminal:**

  ```bash
  # (Inside the dev-container)
  curl https://gitlab.cicd.local:10300
  ```

In both cases, you should see a `302 Found` redirect and the HTML for the login page. The commands will work without any `-k` or `--insecure` flags, proving that both your host and your dev-container trust our new GitLab instance. This confirms that your host port mapping, internal DNS, and end-to-end SSL are all working perfectly.

# Chapter 5: UI Configuration (Securing the Workflow)

With our GitLab container running, secured, and accessible, the "construction" phase is complete. We now put on our "administrator" hat. The next steps involve configuring the GitLab application itself, creating the structures for our teams, and securing our development workflow.

We will also complete the setup for one of our "baked-in" configurations: the `GMAIL_APP_PASSWORD`.

## 5.1. UI Guide: Creating a Google "App Password"

In our `01-initial-setup.sh` script, we "baked" a `GMAIL_APP_PASSWORD` into our `gitlab.rb` file. This is **not** your normal Gmail password. Google's modern security ("Less Secure Apps" deprecation) requires us to generate a special, 16-character password for third-party applications like GitLab.

If you haven't generated this password yet, here is the new, more direct process:

1.  Go to your Google Account settings: **[myaccount.google.com](https://myaccount.google.com/)**
2.  Navigate to the **Security** tab.
3.  Ensure **2-Step Verification** is turned **On**. You cannot create App Passwords without it.
4.  Use the search bar at the top of your account page and type in **"App Passwords"**. Click the result.
5.  You will be prompted to sign in again for security.
6.  On the App Passwords screen, you will be prompted to give your new password a name.
  * **App name:** Give it a descriptive name, like **"GitLab-CICD"**.
  * Click **Generate**.
7.  Google will present you with a 16-character password in a yellow box (e.g., `xxxx yyyy zzzz wwww`).
8.  This is the password you must place in your `~/cicd_stack/cicd.env` file for the `GMAIL_APP_PASSWORD` variable.

If you already had this set up, your email notifications for password resets and new accounts will now work. If you just generated this password for the first time, you must:

1.  Update your `~/cicd_stack/cicd.env` file with the new password.
2.  Re-run `./01-initial-setup.sh` to "re-bake" the `gitlab.rb` file with the new password.
3.  Restart the container to apply the new configuration: `docker stop gitlab && docker start gitlab`. I had encountered a problem with just using `docker restart gitlab`

### 5.1.1. (Optional) Verifying Your SMTP Setup

Now that you have your Gmail App Password configured, you can directly test GitLab's email functionality from within the container.

1.  First, open a "Rails console" session inside your running GitLab container. This command will drop you into an interactive Ruby prompt:

    ```bash
    sudo docker exec -it gitlab gitlab-rails console
    ```

    *(Note: It is normal for this to take 30-60 seconds to load.)*

2.  Once you see the `irb(main):001:0>` prompt, type the following command, replacing the email address with your own. The `.deliver_now` is crucial as it forces the email to be sent immediately:

    ```ruby
    Notify.test_email('your_email@gmail.com', 'GitLab Test Email', 'This is a test message from your GitLab instance.').deliver_now
    ```

3.  After a few seconds, you should see a large object output (the email object) and then a `=>` line.

4.  Type `exit` to leave the console.

Within a minute, you should receive the test email in your Gmail inbox. If you do, your SMTP is configured perfectly. If not, double-check your `GMAIL_APP_PASSWORD` in `cicd.env` and your `smtp_user_name` in `gitlab.rb`.

## 5.2. UI Guide: Creating Our Groups

As we discussed in **Chapter 1**, GitLab's key architectural advantage is its hierarchical **"Group"** system. A "Group" is like a "University Campus" or a top-level organization. It can contain both projects and even *sub-groups* (like "departments").

We will create two top-level "Groups" to properly organize all our projects:
1.  **`CICD-Stack`**: This will house test projects specific to our CI/CD pipeline, like the `hello-world` project we'll create later.
2.  **`Articles`**: This will be the new home for all the projects we've built in previous articles, like `0004_std_lib_http_client`.

Let's create both now.

1.  From the GitLab dashboard, click the **plus icon (`+`)** in the top-left area of the navigation sidebar (it's to the left of your user avatar).
2.  A dropdown menu will appear. Select **"New group"**.
3.  On the next page, you'll be asked what you want to create. Click the large **"Create group"** tile or button.
4.  This brings you to the "Create group" form:
  * **Group name:** Type `CICD-Stack`.
  * **Group URL:** This will auto-populate based on the name.
  * **Visibility level:** Select **"Private"**. This ensures only logged-in members of your instance can see this group and its projects.
  * (Optional) You can skip the "personalize" questions for now.
5.  Click the blue **"Create group"** button at the bottom-left of the page.

You will be taken to the new group's page. Now, let's repeat this exact process for our `Articles` group.

6.  Click the **plus icon (`+`)** in the top-left sidebar again.
7.  Select **"New group"**.
8.  Click the **"Create group"** tile.
9.  On the "Create group" form:
  * **Group name:** Type `Articles`.
  * **Visibility level:** Select **"Private"**.
10. Click the **"Create group"** button.

We now have our two top-level namespaces. This structure keeps our work organized and allows us to set permissions at the group level, which all projects inside will automatically inherit.

## 5.3. UI Guide: Fixing the Root Admin's Email

When GitLab first starts, it assigns a "dummy" email address to the `root` user (e.g., `gitlab_admin_0537fd@example.com`). If you've just tested your SMTP settings as we did in 5.1.1, you may have seen a bounce-back email in your Gmail inbox, because this default email address is not real.

> **Example Bounce-back Error:**
>
> ```
> Address not found
> ```

> Your message wasn't delivered to gitlab\_admin\_0537fd@example.com because the domain example.com couldn't be found. Check for typos or unnecessary spaces and try again.
> ...
> The domain example.com doesn't receive email...
>
> ```
> ```

We must fix this by assigning your *real* email address to the `root` account. This involves a critical "gotcha" where we must manually fix a confirmation link.

Here is the full process:

1.  **Add Your New Email:**

  * Click your `root` user avatar (top-left corner).
  * Select **"Preferences"**.
  * In the left-hand navigation menu, click **"Emails"**.
  * In the "Add email address" box, type your real email address (e.g., `your.name@gmail.com`) and click the **"Add email address"** button.

2.  **Find the Confirmation Email:**

  * GitLab will send a confirmation link to your inbox. Open the email (Subject: "Administrator, confirm your email address now\!").

3.  **Fix the Confirmation Link (The "Gotcha"):**

  * **Do not click the link directly.** The link in the email will be broken. It will point to the *internal* container address (e.g., `https://gitlab/...`), which your host browser cannot resolve.
  * You must manually copy the link and replace the `https://gitlab.cicd.local:10300` portion with our host-accessible address: `https://127.0.0.1:10300`.

    > **Example:**

    > **Broken Link (from email):**
    > `https://gitlab.cicd.local:10300/-/profile/emails/confirmation?confirmation_token=zFoxv_5xPMRiEjfgzR-E`

    > **Corrected Link (to paste in browser):**
    > `https://127.0.0.1:10300/-/profile/emails/confirmation?confirmation_token=zFoxv_5xPMRiEjfgzR-E`

4.  Paste the **corrected link** into your browser and hit Enter. Your email address will now be confirmed.

5.  **Change Your Primary Email:**

  * Now, you must make this new, confirmed email your primary address.
  * Navigate back to your profile: **Avatar \> Preferences**. You will land on the **"Profile"** page.
  * Change the **"Email"** field from the fake `example.com` address to your new, confirmed email.
  * Change the **"Commit email"** field to your new, confirmed email as well.
  * Click the **"Update profile settings"** button at the bottom.

6.  **Clean Up the Old Email:**

  * Finally, let's remove the old, fake email.
  * Go back to the **"Emails"** settings page (left-hand navigation).
  * You will now see your new email listed as "Primary." Click the **"Delete"** (trash can) icon next to the old `gitlab_admin_..._@example.com` address to remove it.

Your `root` account is now fully configured with a valid, working email address for all notifications.

## 5.4. UI Guide: Creating Access Tokens

Our GitLab instance is now fully configured, but to automate it (our ultimate goal), we need to interact with its API. To do this securely, we will create **Access Tokens**. These are the "keys" that our scripts and external services (like Jenkins) will use to authenticate with GitLab.

We will create two different types of tokens to understand the options available. Note: You might want to do section 5.4.3 first.

1.  **Personal Access Token (PAT):** This token is tied directly to a *user account* (in this case, our `root` admin). It's a "master key" that grants permissions *as that user*. It can do anything the `root` user can do.
2.  **Group Access Token (GAT):** This is a more modern, secure "bot" token. It is tied to a *Group* (e.g., our `CICD-Stack` group) instead of a human user. This is the best practice for CI/CD, as the token's permissions are limited *only* to that group, and it's not tied to a person who might leave the company.

For our verification scripts, we will create and use a **Personal Access Token** for our `root` user, as it's the most powerful and straightforward to use for our "master plan" of creating projects in multiple groups.

### 5.4.1. Creating a Personal Access Token (PAT)

1.  In the top-left corner of the sidebar, click your `root` user avatar.
2.  From the dropdown menu, select **"Preferences"**.
3.  In the left-hand navigation menu of the Preferences page, click **"Personal Access Tokens"**.
4.  You will see the "Add a personal access token" form:
  * **Token name:** Give it a descriptive name, like `cicd-admin-token`.
  * **Expiration date:** For now, you can leave it blank (it will not expire). For a real production system, you would set a strict expiration date and rotate the key.
  * **Select scopes:** Check the box for **`api`**. This is the master scope that grants the token full read/write access to the entire API, which we need to create groups and projects.
5.  Click the **"Create personal access token"** button.

GitLab will immediately display your new token (e.g., `glpat-xxxxxxxxxxxx`). **This is the only time you will ever see this token.**

Copy this token immediately and save it in our secrets file, `~/cicd_stack/cicd.env`. Add it as a new line:

```ini
GITLAB_API_TOKEN="glpat-xxxxxxxxxxxx"
```

Our Python scripts in the next chapter will read this variable to authenticate.

### 5.4.2. Creating a Group Access Token (GAT)

Now, let's create a Group Access Token for our `CICD-Stack` group. This is the more modern, "best-practice" way to create a token for automation *within* a specific group.

1.  In the top-left sidebar, click the **"Groups"** icon and select **"Your groups"**.
2.  Click on the **`CICD-Stack`** group.
3.  In the group's left-hand sidebar, hover over **"Settings"** and then click **"Access Tokens"**.
4.  Click the **"Add new token"** button.
5.  Fill out the form:
  * **Token name:** Give it a descriptive name, like `cicd-stack-bot-token`.
  * **Role:** Select **"Owner"**. This is the highest permission *within the group* and will allow this token to create new projects *inside* the `CICD-Stack` group.
  * **Select scopes:** Check the **`api`** scope.
6.  Click the **"Create group access token"** button.

Just like the PAT, this token will be displayed only once. You don't need to save it for our next steps (as we'll be using the PAT), but it's crucial to understand this is the more secure, preferred method for production CI/CD automation.

### 5.4.3. The "Split-Horizon" Fix: Resolving CORS Errors

As you attempted to create an Access Token, you likely ran into a critical error. The page failed to load, and your browser's developer console showed a **`Cross-Origin Request Blocked` (CORS)** error.

This is a classic "split-horizon" DNS problem, and it's the final major "gotcha" in our setup.

#### The Problem

The error occurred because our browser and our application had two different ideas of "home":

1.  **The Browser:** We were accessing the UI from `https://127.0.0.1:10300`.
2.  **The Application:** GitLab's `external_url` was set to `https://gitlab.cicd.local:10300`.

When the UI (loaded from `127.0.0.1`) tried to make an API call, its JavaScript (which was configured by `external_url`) tried to contact `https://gitlab.cicd.local:10300`. The browser saw that `127.0.0.1:10300` and `gitlab.cicd.local` were two different "origins" and blocked the request for security.

#### The Solution

To fix this, we must make the URL we type in the browser **exactly match** the `external_url` in the GitLab configuration. This requires a three-part fix.

**Step 1. Teach Your Host What `gitlab.cicd.local` Means**

First, we must edit the `hosts` file on our **host machine** (not the dev-container) to resolve `gitlab.cicd.local` to our `localhost` IP.

* Open your hosts file with `sudo`:
  ```bash
  sudo nano /etc/hosts
  ```
* Add this line to the bottom of the file:
  ```
  127.0.0.1   gitlab.cicd.local
  ```
* Save and close the file. Your host machine now knows that `gitlab.cicd.local` points to `127.0.0.1`.

**Step 2. Update `01-initial-setup.sh` (The `external_url`)**

Next, we must tell GitLab to include our custom port in its `external_url`. This tells the application to generate all its internal links with the correct port, solving the CORS mismatch.

* Open `01-initial-setup.sh` and find this line in the `gitlab.rb` section:
  ```ruby
  # --- Main GitLab URL ---
  external_url 'https://gitlab.cicd.local'
  ```
* Change it to include our port:
  ```ruby
  # --- Main GitLab URL ---
  # This sets the public URL AND configures the internal NGINX
  # to listen on this port (e.g., 10300).
  external_url 'https://gitlab.cicd.local:10300'
  ```
* **The "Gotcha":** We discovered that changing this `external_url` *also* changes the internal port that GitLab's NGINX service listens on. It will no longer listen on `443`; it will now listen on `10300`.

**Step 3. Update `02-create-docker.sh` (The Port Mapping)**

Finally, because the container's internal port is now `10300`, we must update our `docker run` command to match.

* Open `02-create-docker.sh` and find this line:
  ```bash
  --publish 127.0.0.1:10300:443 \
  ```
* Change it to map `10300` on the host to `10300` in the container:
  ```bash
  --publish 127.0.0.1:10300:10300 \
  ```

**Step 4. Relaunch and Access by Name**

To apply these changes, you **do not need to delete your data**. Simply re-run the scripts.

1.  **Stop and remove the old container.** This is required to apply the new `--publish` flag.
    ```bash
    docker stop gitlab && docker rm gitlab
    ```
2.  **Re-run the setup script.** This will update the `gitlab.rb` file on your host.
    ```bash
    ./01-initial-setup.sh
    ```
3.  **Re-run the deployment script.** This will create a new container with the correct port mapping, which will then read your updated `gitlab.rb` file and reconfigure itself.
    ```bash
    ./02-create-docker.sh
    ```

After waiting a few minutes for the container to start, clear your browser cache (or use a private window). From now on, to access the UI, you **must** use the new, correct URL in your browser:

**[https://gitlab.cicd.local:10300](https://gitlab.cicd.local:10300)**

When you do, the "origin" will match (`https, gitlab, 10300`), the CORS errors will be gone, and all UI features will now work perfectly. You can now proceed with creating your Access Tokens.

> NOTE
> The scripts will be fixed by the time you read this, so all you really need to do is edit your hosts file.

## 5.5. The "Workflow" Pain Point (Enforcing MRs)

Our GitLab instance is now fully configured, but it has a major **workflow problem**. By default, any developer with access to a project can commit and push *directly* to the `main` branch.

> **The Analogy:** This is like letting any engineer walk into the "Central Library" and scribble directly on the "master blueprint" *without* a review.

This "pain point" defeats the entire purpose of our CI/CD pipeline. We *want* every change to be a "proposal" (a Merge Request) that can be reviewed, tested, and scanned *before* it's merged into our "single source of truth."

The solution is to apply a **Branch Rule**. This feature allows us to lock the `main` branch and enforce our Merge Request workflow.

Based on the documentation, there is a key distinction between the Free and Premium tiers:
* **GitLab Free (Our Version):** We can control *who* is allowed to push or merge to a branch. This is the core functionality we need.
* **GitLab Premium/Ultimate:** This adds *required approvals* (e.g., "requires 2 approvals") and status checks.

We will now use the Free tier's "Branch rule" capability to set our core push/merge permissions.

---

## 5.6. Action (UI): Configuring a Branch Rule

We will now enforce our workflow. We'll create a "hello-world" project and apply the "Branch rule," but this time, we'll ensure the `main` branch exists *first*.

1.  First, let's create the project. Navigate to the **`CICD-Stack`** Group you created.
2.  Click the **"New project"** button (top-right).
3.  Select **"Create blank project"**.
4.  **Project name:** `hello-world`
5.  **Visibility Level:** `Private`.
6.  **✅ Check the box for "Initialize repository with a README."**
    This is the crucial step. It creates the project *with* a `main` branch and a single, initial commit.
7.  Click **"Create project"**.

You will be taken to the new project's main page, and you will see the `README.md` file is already there. The `main` branch now officially exists.

*Now* we can protect it.

8.  In the project's left-hand navigation sidebar, go to **Settings > Repository**.
9.  Find the **"Branch rules"** section and click the **"Expand"** button.
10. Click the **"Add branch rule"** button.
11. You will be prompted to choose a target. Select **"Branch name or pattern"**.
12. From the dropdown, select `main`.
13. Click the **"Create branch rule"** button.

This will create the rule and take you to the **Branch rule details** page.

14. On this details page, find the **"Protected branch"** section.
    * **Allowed to merge:** In the dropdown, select **"Maintainers"**.
    * **Allowed to push and merge:** In the dropdown, select **"No one"**.

You can now save these changes. The `main` branch is now "locked."

From this point forward, no one can push directly to `main`. The only way to update it is to push a new feature branch and open a Merge Request, which is exactly the professional workflow we want.

## 6.1. Verification (Part 1): The "API-First" Test (Project Creation)

Our first test will be to use the **Personal Access Token (PAT)** we created in Chapter 5. This test will prove that our API is accessible, our token is working, and our Python environment on our **host machine** can successfully talk to our container.

This test is the **ultimate payoff for Article 2**. We will not be manually loading any CA files. We will use Python's standard `ssl.create_default_context()`, which now automatically uses our host's system trust store (where our Local CA was installed).

Create the following Python script on your host machine. You can save it as `verify_gitlab.py` inside your `~/cicd_stack` directory.

```python
import os
import ssl
import json
import urllib.request
from pathlib import Path

# --- Configuration ---
ENV_FILE_PATH = Path.home() / "cicd_stack" / "cicd.env"
GITLAB_URL = "https://gitlab.cicd.local:10300" # Our host-accessible URL
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
```

### Running the Verification

1.  **Run the Script (No Dependencies Required):**
    ```bash
    python3 verify_gitlab.py
    ```

**The Payoff:**
You should see the following output:

```
Loading environment from: /home/your_user/cicd_stack/cicd.env
Creating default SSL context...
Searching for Group ID for: Articles...
Found Group ID: 2
Creating project '0004_std_lib_http_client' in Group ID 2...
✅ Success! Project created.
  ID: 3
  URL: https://gitlab.cicd.local:10300/Articles/0004_std_lib_http_client
```

This simple, dependency-free script verifies a massive amount of our architecture:

1.  Our `/etc/hosts` file is working (it found `gitlab`).
2.  Our Docker port mapping is correct (it reached `10300`).
3.  Our **host's system trust store is working perfectly** (the SSL connection succeeded with `ssl.create_default_context()` and no other arguments).
4.  Our `gitlab.rb` SSL config is working.
5.  Our Personal Access Token is valid and has `api` scope.
6.  Our `Articles` group is set up and accessible.

Go to the GitLab UI (`https://gitlab.cicd.local:10300`). You will now see your new **`0004_std_lib_http_client`** project, complete without a `README.md`, inside the `Articles` group.

## 6.2. Verification (Part 2): The "Internal Push" & Webhook Test

This is the full-stack test of our `cicd-net` architecture. We will simulate our entire CI/CD pipeline. Our `dev-container` will act as a developer pushing a change *and* as the "Jenkins" server receiving the webhook.

This test will prove:

* **Internal DNS:** The dev-container can resolve `gitlab`.
* **GitLab's CA Trust:** GitLab (as a client) trusts our internal services.
* **Webhook Mechanism:** GitLab correctly fires a webhook on a push.

### Action 1 (Admin UI): The "SSRF" Gotcha - Allowing Local Webhooks

Before we can set up the webhook, we must first get past the `Invalid url given` error. We need to tell GitLab that it's allowed to send requests to our internal `dev-container`.

1.  As your `root` user, go to the **Main menu** (top-left waffle icon) and click **"Admin"** (the wrench icon).
2.  In the Admin Area's left-hand sidebar, navigate to **Settings \> Network**.
3.  Find the **"Outbound requests"** section and click the **"Expand"** button.
4.  Find the checkbox labeled **"Allow requests to the local network from web hooks and services"**.
5.  **Check** this box.
6.  (Optional but Recommended) For a more secure setup, you can leave the box *unchecked* and instead add `dev-container` (and later, `jenkins`) to the allowlist in the "Local IP addresses and domain names that hooks and integrations can access" text box. For our purposes, checking the main "Allow" box is the simplest solution.
7.  Click the **"Save changes"** button at the bottom of the section.

Now that we've told GitLab to trust our local network, the `Invalid url given` error will be gone.

### Action 2 (UI): Set Up the Webhook

Now, let's try this step again.

1.  In the GitLab UI, navigate to your **`hello-world`** project (inside the `CICD-Stack` group).
2.  In the project's left-hand sidebar, go to **Settings \> Webhooks**.
3.  Fill out the webhook form:
    * **URL:** `https://dev-container:10400`
    * **Secret token:** Create a simple secret, for example, `my-super-secret-token`. We will use this to verify the request.
    * **Trigger:** Uncheck everything *except* **"Push events"**.
    * **SSL verification:** Make sure **"Enable SSL verification"** is **CHECKED**. This is the whole point of the test.
4.  Click **"Add webhook"**.

This time, it will work. GitLab will send a test event, which will still fail (with a "Hook execution failed" error) because our `webhook_receiver.py` isn't running yet. This is expected.

### Action 3 (Host): Generate and Stage the `dev-container` Certificate

Before we can run our server, we must give it a valid "passport." We'll use our Article 2 CA scripts from our **host machine** to generate a new certificate for the hostname `dev-container`.

Then, we'll copy those new certs into the `~/Documents/FromFirstPrinciples/data` directory, which is mounted inside our dev container as `~/data`.

1.  Open a terminal on your **host machine** (not the dev-container).

2.  Navigate to your Article 2 script directory:

    ```bash
    # (On your HOST machine)
    cd ~/Documents/FromFirstPrinciples/articles/0006_cicd_part02_certificate_authority
    ```

3.  Run the `02-issue-service-cert.sh` script from here, passing `dev-container` as the name. This script is smart enough to operate on the `~/cicd_stack/ca` directory.

    ```bash
    ./02-issue-service-cert.sh dev-container
    ```

    This will create the new certs in `~/cicd_stack/ca/pki/services/dev-container/`.

4.  **Copy the new certs** to the dev container's shared data volume (which, as you noted, already exists):

    ```bash
    # (On your HOST machine)
    DATA_DIR=~/Documents/FromFirstPrinciples/data
    CERT_SOURCE_DIR=~/cicd_stack/ca/pki/services/dev-container

    cp $CERT_SOURCE_DIR/dev-container.crt.pem $DATA_DIR/
    cp $CERT_SOURCE_DIR/dev-container.key.pem $DATA_DIR/
    ```

### Action 4 (Dev Container): The "Jenkins" Simulator

Now, let's go back to your **dev container**. We will create the simple Python server that will act as our "Jenkins" instance, placing it in the correct article directory. It will listen on port `10400` and use the `dev-container` certificate we just staged in the `~/data` directory.

1.  **Create the server script:**
    Navigate to your article directory and create the new Python file.

    ```bash
    # (Inside the dev container)
    cd ~/articles/0007_cicd_part03_gitlab
    nano webhook_receiver.py
    ```

2.  **Paste in the following code.** Note the updated certificate paths pointing to `~/data`.

    ```python
    import http.server
    import ssl
    import json
    import os

    # --- CONFIGURATION ---
    LISTEN_HOST = '0.0.0.0'
    LISTEN_PORT = 10400
    SECRET_TOKEN = 'my-super-secret-token' # Must match your GitLab webhook

    # Paths to our *new* dev-container certs in the ~/data mount
    CERT_DIR = os.path.expanduser('~/data')
    CERT_FILE = os.path.join(CERT_DIR, 'dev-container.crt.pem')
    KEY_FILE = os.path.join(CERT_DIR, 'dev-container.key.pem')

    class WebhookHandler(http.server.BaseHTTPRequestHandler):
        def do_POST(self):
            # 1. Verify the Secret Token
            gitlab_token = self.headers.get('X-Gitlab-Token')
            if gitlab_token != SECRET_TOKEN:
                print("⛔ ERROR: Invalid X-Gitlab-Token.")
                self.send_response(403)
                self.end_headers()
                return
            
            # 2. Read the JSON payload
            content_length = int(self.headers['Content-Length'])
            body = self.rfile.read(content_length)
            
            # 3. Print the relevant info
            print("\n--- ✅ WEBHOOK RECEIVED! ---")
            try:
                payload = json.loads(body)
                print(f"Project: {payload.get('project', {}).get('path_with_namespace')}")
                print(f"Pusher:  {payload.get('user_name')}")
                print(f"Ref:     {payload.get('ref')}")
                
                # Print all commits in this push
                for commit in payload.get('commits', []):
                    print(f"  - Commit: {commit.get('id')[:8]}")
                    print(f"    Author: {commit.get('author', {}).get('name')}")
                    print(f"    Msg:    {commit.get('message').strip()}")
                    
            except Exception as e:
                print(f"Error parsing JSON: {e}")
            
            # 4. Send a 200 OK response
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b'Webhook Received')

    if __name__ == "__main__":
        print(f"Starting HTTPS server on https://{LISTEN_HOST}:{LISTEN_PORT}...")
        
        # Create an SSL context using our "dev-container" certs
        context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
        context.load_cert_chain(certfile=CERT_FILE, keyfile=KEY_FILE)
        
        httpd = http.server.HTTPServer((LISTEN_HOST, LISTEN_PORT), WebhookHandler)
        httpd.socket = context.wrap_socket(httpd.socket, server_side=True)
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down server...")
            httpd.server_close()
    ```

3.  **Run the server:**

    ```bash
    # (Inside the dev-container, from the 0007... directory)
    python3 webhook_receiver.py
    ```

    You should see: `Starting HTTPS server on https://0.0.0.0:10400...`

Our "Jenkins" simulator is now running with a valid, matching certificate, waiting for a signal.

### Action 5 (Dev Container): The Git Push

Finally, let's act as a developer. We'll open a **second `dev-container` terminal** (leave your `webhook_receiver.py` server running in the first one).

We will clone the `hello-world` project, attempt to push to `main` (which will fail), and then successfully push a feature branch (which will trigger our webhook).

### 1\. Configure Git

Before your first push, you must tell Git who you are.

> **Note on Automation:** Our dev container is set up to automatically source a Git configuration from `~/data/.gitconfig` at startup. For a fully automated setup, you could place your `.gitconfig` file in the `~/Documents/FromFirstPrinciples/data` directory on your host, and your container would pick it up on every boot.

For now, we'll run the manual, one-time commands:

```bash
# (Inside the dev-container)
git config --global user.name "Your Name"
git config --global user.email "your.email@gmail.com"
```

(Use the email address you registered with GitLab in section 5.3).

### 2\. Clone the Repository

Navigate to your `repos` directory, where we'll clone the project.

```bash
# (Inside the dev-container)
cd ~/repos
git clone https://gitlab.cicd.local:10300/CICD-Stack/hello-world.git
```

You will now be prompted for credentials. This is the crucial step for Git-over-HTTPS:

* **Username:** `root`
* **Password:** **Do NOT use your root password.** Instead, copy and paste the **Personal Access Token (PAT)** (`glpat-...`) that you saved in your `cicd.env` file. This is the standard, secure way to authenticate Git clients.

After you authenticate, Git will clone the repository:

```
Cloning into 'hello-world'...
Username for 'https://gitlab.cicd.local:10300': root
Password for 'https://root@gitlab.cicd.local:10300': 
remote: Enumerating objects: 3, done.
remote: Counting objects: 100% (3/3), done.
remote: Compressing objects: 100% (2/2), done.
remote: Total 3 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
Receiving objects: 100% (3/3), done.
```

Now, `cd` into the new project:

```bash
cd hello-world
```

### 3\. Create Our First Commit (The Failed Push)

Recall that we *protected* the `main` branch. This means our push to `main` **must fail**.

```bash
# (Inside the dev-container)
# We will just edit the README that was created when we made the project.
echo "Hello World!" >> README.md
git add .
git commit -m "Test commit to main"

# This push will be REJECTED by our branch rule
git push -u origin main
```

**The Payoff (Part 1):** You will see this error, proving our rule is working:

```
remote: GitLab: You are not allowed to push code to protected branches on this project.
! [remote rejected] main -> main (pre-receive hook declined)
```

### 4\. Push Correctly (The Successful Push)

Now, let's do it the *right* way by creating a feature branch.

```bash
# (Inside the dev-container)
git checkout -b feature/initial-commit

# We already have the commit, so we just push the new branch
git push -u origin feature/initial-commit
```

This push will **succeed**.

-----

### The Payoff (Part 2)

Now, look at your *first* dev-container terminal (the one running `webhook_receiver.py`). You will see:

```
--- ✅ WEBHOOK RECEIVED! ---
Project: CICD-Stack/hello-world
Pusher:  Your Name
Ref:     refs/heads/feature/initial-commit
  - Commit: <some_hash>
    Author: Your Name
    Msg:    Test commit to main
```

This single test confirms our entire internal architecture is working perfectly:

1.  **Internal DNS:** `git clone https://gitlab.cicd.local:10300` worked.
2.  **Authentication:** Our Personal Access Token worked for Git authentication.
3.  **Branch Rules:** Our push to `main` was correctly **rejected**.
4.  **Webhook Trigger:** Our push to `feature/initial-commit` was successful and **fired the webhook**.
5.  **GitLab CA Trust:** GitLab (as a client) saw our `https://dev-container:10400` URL, validated its certificate (which has the correct hostname `dev-container`) against the `ca.pem` we mounted in `trusted-certs`, and successfully made the HTTPS request.

We have now verified our setup from end to end.

## 6.3. Verification (Part 3): The "External Push" (Practical Application)

We have successfully verified our *internal* network (dev-container to GitLab). This final test is the payoff for our **host machine** setup from Article 2. We will prove that our *external* (host-to-container) workflow is working just as smoothly.

We will `cd` into our *existing* `0004_std_lib_http_client` repository on our host machine, add our new GitLab instance as a "remote," and push our code.

This push will **only succeed** because:

1.  Our host's `/etc/hosts` file can resolve `gitlab.cicd.local` to `127.0.0.1`.
2.  Our `git` CLI (like our Python script) uses the **system trust store**, which we fixed in Article 2 to trust our Local CA.

### Action 1 (Host): Add the New Remote

1.  On your **host machine's terminal**, navigate to the existing project directory from our previous article:

    ```bash
    # (On your HOST machine)
    cd ~/Documents/FromFirstPrinciples/articles/0004_std_lib_http_client
    ```

2.  Add our new GitLab instance as a remote. We'll call it `gitlab`. We use the `https://gitlab.cicd.local:10300` URL that our host can now resolve.

    ```bash
    git remote add gitlab https://gitlab.cicd.local:10300/Articles/0004_std_lib_http_client.git
    ```

3.  (Optional) Verify the new remote was added:

    ```bash
    git remote -v
    ```

    You should see `gitlab` listed along with `origin` (which likely points to GitHub).

### Action 2 (Host): Push to GitLab

Now, let's push our `main` branch to the new `gitlab` remote.

```bash
# (On your HOST machine)
git push -u gitlab main
```

Just as you did in the dev container, you will be prompted for credentials:

* **Username:** `root`
* **Password:** (Paste your **Personal Access Token**, `glpat-...`)

**The Payoff:**
The push will succeed without any SSL errors. `git` will not complain about an "untrusted certificate" because it's using your host's trust store.

You have now:

1.  Created a project (`0004_std_lib_http_client`) via the API.
2.  Pushed your existing local code to it from your host machine.

Go to the GitLab UI and look at your `0004_std_lib_http_client` project. It will no longer be empty. It will now contain all the code from your local repository, and its `main` branch is now populated.

# Chapter 7: Conclusion

## 7.1. What We've Built: The "Central Library" is Open

Let's take a moment to appreciate what we have just accomplished. We have successfully deployed a fully-featured, secure, and production-ready **GitLab** instance entirely from first principles.

This isn't just a container; it's the **"Central Library"** of our new CI/CD city, and it is built on a rock-solid, architecturally-sound foundation.

* It lives **inside our private `cicd-net`**, able to communicate with our other services using internal DNS.
* It is **fully secured with SSL**, serving traffic over HTTPS using a certificate from our own Local Certificate Authority.
* It **trusts our Local CA**, allowing it to send secure webhooks to *other* internal services like our `dev-container` (and later, Jenkins).
* It is configured for **professional team workflow** using "Branch Rules" to protect `main` and enforce Merge Requests.
* It is **fully automated**, with a "baked-in" `gitlab.rb` file that handles everything from the root password to our SMTP settings, solving the complex "first-run" conflict.
* It is **fully verifiable**, proven to work from the API (Python script), the internal network (dev-container Git push), and the external host (host Git push).

We have solved every "pain point" we set out to address: network isolation, data sovereignty, and the "paid feature" trap. We have built our library *inside* our city walls.

## 7.2. The Next "Pain Point"

We have successfully built our "Central Library" (GitLab) and proven that our code (like `hello-world` and `0004_http_client`) is now safely stored inside, "on the shelf."

This introduces our next, obvious "pain point."

Our code is just **sitting there**.

Our `dev-container` test was a simulation, but it revealed the truth: a webhook is firing, but it's just hitting a test server. We have no "factory" to *act* on this signal. We have no automated process to:
* Compile our code.
* Run our unit tests.
* Scan our code for quality or security vulnerabilities.
* Build our code into a Docker image.
* Publish our finished "product."

Our "Central Library" is open, but the "Factory" next door is an empty lot.

---

## 7.3. Next Steps

We must now build that factory. Our webhook signal needs a real target, an "Automation Foreman" that can receive the "new code" signal from GitLab and start a complex assembly line.

In the next article, we will do exactly that. We will build the second "skyscraper" in our CI/CD city: **Jenkins**. We will deploy the Jenkins controller, connect it to our `cicd-net`, and configure it to receive the webhooks from GitLab, officially kicking off our automated pipeline.

## Addendum: Best Practices - Creating a Daily User Account

We have successfully set up and verified our entire GitLab instance using the `root` administrator account. While this was necessary for the initial setup, using the `root` account for daily work or CI/CD integrations is a **significant security risk**.

### Why You Shouldn't Use `root`

The `root` user is an "all-powerful" administrator. It can instantly delete all projects, change critical instance settings, or remove other users. If this account's credentials (or its Personal Access Token) were ever leaked, your entire "Central Library" would be compromised.

We will now follow the **Principle of Least Privilege** by creating a regular user account for our daily work.

### 1. Create Your Unprivileged User

1.  As the `root` user, go to the **Main menu** (top-left waffle icon) and click **"Admin"** (the wrench icon).
2.  In the Admin Area's left-hand sidebar, navigate to **Overview > Users**.
3.  Click the **"New user"** button in the top-right.
4.  Fill out the form for your new "daily driver" account:
    * **Full name:** (e.g., `Warren Jitsing`)
    * **Username:** (e.g., `warren.jitsing`)
    * **Email:** (e.g., `your.email@gmail.com`)
5.  **Password:** The "Password" field is just a reset link. The new user will receive an email at the address you just provided, prompting them to set their own password.
6.  **Access level:** Leave this as **"Regular"**. This means they are a regular user, not an instance administrator.
7.  Click **"Create user"**.

You will now need to log out of your `root` account, check your email, and follow the confirmation link to set the password for your new `warren.jitsing` user.

### 2. Add Your User to Your Groups

After setting your new user's password, log out and log back in as your new, non-admin user (e.g., `warren.jitsing`). You will notice you can't see any of your projects. This is because your new user has not been granted any permissions.

We must now add this user to our Groups as a **Maintainer**.

1.  Log out of your new user and log *back in* as `root`.
2.  Navigate to your groups: **Main menu > Groups > Your groups**.
3.  Click on the **`CICD-Stack`** group.
4.  In the group's left-hand sidebar, navigate to **Manage > Members**.
5.  Click the **"Invite members"** button.
6.  In the "GitLab member or email address" box, type the username of your new user (e.g., `warren.jitsing`) and select them.
7.  **Select a role:** Choose **"Maintainer"**. This gives the user high-level access *within the group* (like creating new projects and managing branch rules) without making them an instance administrator.
8.  Click **"Invite"**.
9.  Repeat this entire process for your **`Articles`** group.

### Next Steps: Moving Away from `root`

You can now log out as `root` and log in as your new "Maintainer" user. You will have full access to both groups and their projects.

From this point forward, we will stop using the `root` account and its Personal Access Token (PAT). In the next article, when we configure Jenkins, we will explore more secure authentication methods, such as using **Group Access Tokens** or **Project Access Tokens**, which are not tied to any human user and are the best practice for CI/CD automation.