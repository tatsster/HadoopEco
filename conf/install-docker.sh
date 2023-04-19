#!/bin/bash

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add current user to docker group to avoid using sudo
sudo usermod -aG docker $(whoami)

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Set environment variables
echo "export AMBARI_PORT=8888" >> ~/.bashrc

# Reload bash profile
source ~/.bashrc
