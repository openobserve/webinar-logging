#!/bin/bash

# Docker Installation Script for Ubuntu

set -e

echo "🐋 Installing Docker on Ubuntu"

# Remove any old Docker installations
echo "📦 Removing old Docker installations..."
sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Update package index
echo "🔄 Updating package index..."
sudo apt-get update

# Install dependencies
echo "📋 Installing dependencies..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
echo "🔑 Adding Docker GPG key..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the Docker repository
echo "📚 Setting up Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again
echo "🔄 Updating package index with Docker repository..."
sudo apt-get update

# Install Docker Engine
echo "🐳 Installing Docker Engine..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker service
echo "🚀 Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group
echo "👤 Adding current user to docker group..."
sudo usermod -aG docker $USER

# Install Docker Compose (standalone)
echo "🧩 Installing Docker Compose..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installations
echo "✅ Verifying installations..."
sudo docker --version
docker-compose --version

echo ""
echo "🎉 Docker installation completed successfully!"
echo ""
echo "⚠️  IMPORTANT: You need to log out and log back in (or restart your terminal)"
echo "    for the docker group changes to take effect."
echo ""
echo "🧪 Test Docker installation:"
echo "    docker run hello-world"
echo ""
echo "🧪 Test Docker Compose:"
echo "    docker-compose --version"

# Create a simple test
cat > test-docker.sh << 'EOF'
#!/bin/bash
echo "Testing Docker installation..."
docker run --rm hello-world
echo ""
echo "Testing Docker Compose..."
docker-compose --version
echo ""
echo "✅ All tests passed! Docker is ready to use."
EOF

chmod +x test-docker.sh
echo "📝 Created test-docker.sh - run this after logging back in to test your installation"