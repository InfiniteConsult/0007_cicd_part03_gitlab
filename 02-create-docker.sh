#!/usr/bin/env bash

# This script launches the GitLab container with all
# the networking, volumes, and security settings.

echo "🚀 Starting GitLab container..."

docker run -d \
  --name gitlab \
  --restart always \
  --hostname gitlab.cicd.local \
  --network cicd-net \
  --publish 127.0.0.1:10300:10300 \
  --publish 127.0.0.1:10301:22 \
  --volume gitlab-data:/var/opt/gitlab \
  --volume gitlab-logs:/var/log/gitlab \
  --volume "${HOME}/cicd_stack/gitlab/config":/etc/gitlab \
  --volume "${HOME}/cicd_stack/ca/pki/services/gitlab.cicd.local":/etc/gitlab/ssl:ro \
  --shm-size 256m \
  gitlab/gitlab-ce:latest

echo "✅ GitLab container is starting."
echo "Monitor its progress with: docker logs -f gitlab"