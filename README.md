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

This breaks the integration. How can `GitHub.com` (on the public internet) send a webhook to `https://jenkins:8443` (a private hostname on our `cicd-net`)? It can't. It's like shouting from the public library and expecting our "factory foreman" (Jenkins) to hear it inside our walled city.

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
external_url 'https://gitlab'

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
```

-----

## 3.5. Deconstruction of `01-initial-setup.sh`

This script is dense, but every step is a deliberate solution to a problem we uncovered. Let's deconstruct it.

* **Step 1: Prerequisite Check**: The script begins with a critical safety check. It ensures the `cicd.env` file we created in 3.1 actually exists. If it doesn't, the script immediately exits with a helpful error message. This prevents us from ever running a misconfigured setup.

* **Steps 2 & 3: Housekeeping**: These steps create the base `~/cicd_stack` directory and add our secret `cicd.env` file to `.gitignore` to prevent us from ever accidentally committing it.

* **Steps 4 & 5: Directory Scaffolding & CA Trust**: This is where we see the first piece of our proactive strategy. The script creates the `gitlab/config` and, crucially, the **`gitlab/config/trusted-certs`** directories. It then immediately copies our `ca.pem` (from Article 2) *into* this `trusted-certs` folder.

  * **This single step solves the "Outbound Trust" problem before it ever begins.** When GitLab starts for the first time, its `reconfigure` script will see our CA certificate already in place and will automatically build its trust store, adding our CA. It will then be able to send secure webhooks to `https://jenkins` or talk to other internal, SSL-secured services without a single SSL error. No second `reconfigure` is ever needed.

* **Step 6: The "Bake-in"**: This is the most important part of the script and the core of our solution.

  1.  **`set -a / source "$ENV_FILE" / set +a`**: This triplet of commands loads our secrets. `source` "runs" the `cicd.env` file, which sets the `GITLAB_ROOT_PASSWORD` and `GMAIL_APP_PASSWORD` variables within the script's environment.
  2.  **`sudo bash -c "cat << EOF > ..."`**: This is the "bake-in" operation. We use `sudo` to gain root privileges, which are necessary to write into the `gitlab/config` directory (as `sudo` created it). The `cat << EOF > $GITLAB_CONFIG_FILE` command writes a "here document" (all the text until the final `EOF`) into our `gitlab.rb` file.
  3.  **Variable Expansion**: Because we `source`'d the variables first, the shell *expands* them *before* `sudo` ever runs. This means the line `gitlab_rails['initial_root_password'] = '${GITLAB_ROOT_PASSWORD}'` becomes `gitlab_rails['initial_root_password'] = 'MySuperSecurePassword123'` *inside* the final file.

-----

## 3.6. Deconstruction of the "Baked" `gitlab.rb`

The `gitlab.rb` file generated by our script is the master blueprint for the entire container. Let's analyze each block:

* **`external_url 'https://gitlab'`**
  This is arguably the most critical setting. It tells GitLab what its "public" URL is. Because all our CI/CD services (like Jenkins, SonarQube, and our dev-container) live on the same `cicd-net`, they will all be able to find and access this container using its internal DNS name, `gitlab`.

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
  --hostname gitlab \
  --network cicd-net \
  --publish 127.0.0.1:10300:443 \
  --publish 127.0.0.1:10301:22 \
  --volume gitlab-data:/var/opt/gitlab \
  --volume gitlab-logs:/var/log/gitlab \
  --volume "${HOME}/cicd_stack/gitlab/config":/etc/gitlab \
  --volume "${HOME}/cicd_stack/ca/pki/services/gitlab":/etc/gitlab/ssl:ro \
  --shm-size 256m \
  gitlab/gitlab-ce:latest

echo "✅ GitLab container is starting."
echo "Monitor its progress with: docker logs -f gitlab"
```

-----

## 4.2. Deconstruction of the `docker run` Command

Every single flag in this command is a deliberate architectural decision, connecting back to the foundations we laid in Articles 1 and 2.

* **`--network cicd-net` & `--hostname gitlab`**: This is the payoff from Article 1. We connect our "skyscraper" to our private "city road network" (`cicd-net`) and give it an internal DNS name (`gitlab`). This is what will allow our dev-container (and later, Jenkins) to find it by simply using the address `https://gitlab`.

* **`--publish 127.0.0.1:10300:443` & `--publish 127.0.0.1:10301:22`**: This is our port mapping scheme.

  * It exposes the container's internal HTTPS (443) and SSH (22) ports to `10300` and `10301` on our host.
  * Critically, it binds **only to `127.0.0.1` (localhost)**. This is a key security choice. It means our GitLab instance is *not* exposed to our local LAN (e.g., your office Wi-Fi). It is only accessible from your host machine.

* **`--volume gitlab-data:/var/opt/gitlab` & `--volume gitlab-logs:/var/log/gitlab`**: This is our "storage locker" persistence strategy from Article 1. We are mounting our pre-made named volumes to store all of GitLab's opaque, internal data (like its database, repositories, and logs).

* **`--volume "${HOME}/cicd_stack/gitlab/config":/etc/gitlab`**: This is the **grand payoff** of our entire "Blueprint First" strategy. We are mounting our *fully-configured* host directory (which contains our baked `gitlab.rb` and `trusted-certs` folder) directly into the container.

* **`--volume "${HOME}/cicd_stack/ca/pki/services/gitlab":/etc/gitlab/ssl:ro`**: This is the payoff from Article 2. We mount our `gitlab` "passport" (its SSL certificate and key) into the container in `ro` (read-only) mode for security.

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
  curl https://gitlab
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
  * You must manually copy the link and replace the `https://gitlab` portion with our host-accessible address: `https://127.0.0.1:10300`.

    > **Example:**

    > **Broken Link (from email):**
    > `https://gitlab/-/profile/emails/confirmation?confirmation_token=zFoxv_5xPMRiEjfgzR-E`

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

We will create two different types of tokens to understand the options available.

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
2.  **The Application:** GitLab's `external_url` was set to `https://gitlab` (implying port 443).

When the UI (loaded from `127.0.0.1`) tried to make an API call, its JavaScript (which was configured by `external_url`) tried to contact `https://gitlab`. The browser saw that `127.0.0.1:10300` and `gitlab` were two different "origins" and blocked the request for security.

#### The Solution

To fix this, we must make the URL we type in the browser **exactly match** the `external_url` in the GitLab configuration. This requires a three-part fix.

**Step 1. Teach Your Host What `gitlab` Means**

First, we must edit the `hosts` file on our **host machine** (not the dev-container) to resolve `gitlab` to our `localhost` IP.

* Open your hosts file with `sudo`:
  ```bash
  sudo nano /etc/hosts
  ```
* Add this line to the bottom of the file:
  ```
  127.0.0.1   gitlab
  ```
* Save and close the file. Your host machine now knows that `gitlab` points to `127.0.0.1`.

**Step 2. Update `01-initial-setup.sh` (The `external_url`)**

Next, we must tell GitLab to include our custom port in its `external_url`. This tells the application to generate all its internal links with the correct port, solving the CORS mismatch.

* Open `01-initial-setup.sh` and find this line in the `gitlab.rb` section:
  ```ruby
  # --- Main GitLab URL ---
  external_url 'https://gitlab'
  ```
* Change it to include our port:
  ```ruby
  # --- Main GitLab URL ---
  # This sets the public URL AND configures the internal NGINX
  # to listen on this port (e.g., 10300).
  external_url 'https://gitlab:10300'
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

**[https://gitlab:10300](https://www.google.com/search?q=https://gitlab:10300)**

When you do, the "origin" will match (`https, gitlab, 10300`), the CORS errors will be gone, and all UI features will now work perfectly. You can now proceed with creating your Access Tokens.

> NOTE
> The scripts will be fixed by the time you read this, so all you really need to do is edit your hosts file. 