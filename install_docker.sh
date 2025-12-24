#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo ">>> Updating package database..."
sudo apt-get update

echo ">>> Installing prerequisites..."
sudo apt-get install -y ca-certificates curl

echo ">>> Setting up Docker GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo ">>> Adding Docker repository to sources..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo ">>> Updating package database with Docker repo..."
sudo apt-get update

# ------------------------------------------------------------------
echo ">>> Pre-configuring Docker daemon settings..."

# Create the directory (using -p to ensure no error if it already exists)
sudo mkdir -p /etc/docker

# Write the configuration to daemon.json
echo '{
  "default-address-pools": [{ "base":"172.80.0.0/16","size":24 }]
}' | sudo tee /etc/docker/daemon.json > /dev/null

echo ">>> Configuration file created at /etc/docker/daemon.json"
# ------------------------------------------------------------------

echo ">>> Installing Docker Engine, CLI, and Compose..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo ">>> Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

echo ">>> Adding current user ($USER) to the docker group..."
sudo usermod -aG docker $USER

echo "=================================================="
echo "Installation Complete!"
echo "Docker version installed:"
docker --version
echo "Docker Compose version installed:"
docker compose version
echo "=================================================="
echo "IMPORTANT: You must log out and log back in (or reboot) for the user permissions to take effect."
echo "=================================================="