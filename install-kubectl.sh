#!/bin/bash
set -euo pipefail

# Install kubectl via the official Kubernetes apt repository

# Dependencies for apt transport
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg

# Add the Kubernetes signing key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add the Kubernetes apt repository
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list

# Install kubectl
sudo apt-get update
sudo apt-get install -y kubectl

echo "kubectl installed successfully: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
