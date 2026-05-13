# Docker Setup

This folder contains the installation script for Docker and Docker Compose on Raspberry Pi.

## Overview

Docker is a containerization platform that allows you to run applications in isolated, lightweight containers. Docker Compose is a tool for defining and running multi-container Docker applications.

In this monitoring infrastructure, Docker is used to run:
- Prometheus (metrics collection)
- Grafana (visualization)
- Home Assistant (home automation)

## Prerequisites

- Raspberry Pi running Debian-based OS (Raspberry Pi OS)
- Internet connection
- SSH access or terminal access to the Pi
- `sudo` privileges

## What Gets Installed

- **Docker Engine**: The core containerization platform
- **Docker CLI**: Command-line interface for Docker
- **containerd**: Container runtime
- **Docker Buildx**: Plugin for building Docker images
- **Docker Compose**: Tool for running multi-container applications

## Installation

### Quick Start

```bash
cd docker_setup
chmod +x install.sh
sudo ./install.sh
```

The script will:
- Update package database
- Install prerequisites (`ca-certificates`, `curl`)
- Setup Docker GPG key and repository
- Install Docker components
- Start and enable Docker service
- Add current user to docker group
- Verify installation

## Post-Installation

After running the installation script, you **must log out and log back in** (or reboot) for the user group changes to take effect.

```bash
# Log out and log back in
logout

# Or reboot
sudo reboot
```

After logging back in, verify Docker works without sudo:

```bash
docker --version
docker run hello-world
```

## Verification

Verify Docker installation:

```bash
# Check Docker version
docker --version

# Check Docker Compose version
docker compose version

# Test Docker by running a simple container
docker run --rm hello-world

# Check Docker service status
sudo systemctl status docker
```

## Configuration

The script pre-configures Docker with a custom network address pool:

```json
{
  "default-address-pools": [{ "base":"172.80.0.0/16","size":24 }]
}
```

This prevents network conflicts and is located at: `/etc/docker/daemon.json`

## Basic Docker Commands

```bash
# List all containers
docker ps -a

# List all images
docker images

# View container logs
docker logs <container_id>

# Stop a container
docker stop <container_id>

# Remove a container
docker rm <container_id>

# Remove an image
docker rmi <image_id>
```

## Docker Compose Commands

```bash
# Start services defined in docker-compose.yml
docker compose up -d

# Stop all services
docker compose down

# View logs
docker compose logs -f

# Rebuild containers
docker compose build

# Pull latest images
docker compose pull
```

## Service Management

```bash
# Start Docker service
sudo systemctl start docker

# Stop Docker service
sudo systemctl stop docker

# Restart Docker service
sudo systemctl restart docker

# Check service status
sudo systemctl status docker

# Enable auto-start on boot
sudo systemctl enable docker

# Disable auto-start
sudo systemctl disable docker
```

## Storage Considerations

Docker stores images and containers in `/var/lib/docker/`. On Raspberry Pi with limited storage, monitor disk usage:

```bash
# Check Docker disk usage
docker system df

# Clean up unused images
docker image prune -a

# Clean up unused containers
docker container prune

# Clean up everything (images, containers, volumes)
docker system prune -a
```

## Troubleshooting

### "permission denied while trying to connect to Docker daemon"
- User not in docker group: `sudo usermod -aG docker $USER`
- Log out and log back in
- Check with: `groups` (should include 'docker')

### "Docker daemon not running"
```bash
# Start the service
sudo systemctl start docker

# Check status
sudo systemctl status docker
```

### "Cannot connect to Docker socket"
```bash
# Check Docker service is running
sudo systemctl status docker

# Check socket permissions
ls -la /var/run/docker.sock

# Restart Docker
sudo systemctl restart docker
```

### Out of disk space
```bash
# Check disk usage
docker system df

# Remove unused images and containers
docker system prune -a --volumes
```

## Next Steps

After Docker is installed, proceed to:
1. **Prometheus & Grafana Setup** - See `../prometheus_grafana_setup/`
2. **Home Assistant Setup** - See `../home_assistant_setup/`

Both use Docker Compose to run their services.

## References

- [Docker Installation Guide](https://docs.docker.com/engine/install/debian/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker Command Reference](https://docs.docker.com/engine/reference/commandline/cli/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
