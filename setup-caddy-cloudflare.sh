#!/bin/bash

# Caddy with Cloudflare DNS Plugin - Quick Setup Script
# This script automates the deployment process described in the guide

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
print_status "Checking prerequisites..."

if ! command_exists docker; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command_exists docker compose; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check if running on ARM64
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ]; then
    print_warning "This script is optimized for ARM64 (aarch64). Current architecture: $ARCH"
    read -p "Continue anyway? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

print_success "Prerequisites check passed"

# Setup directory
INSTALL_DIR="/opt/homelab/caddy"
print_status "Setting up directory structure at $INSTALL_DIR"

# Create directory with proper permissions
sudo mkdir -p "$INSTALL_DIR"
sudo chown "$USER:$USER" "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Copy configuration files
print_status "Copying configuration files..."

# Check if files exist in current directory first
if [ -f "../Dockerfile.caddy-cloudflare" ]; then
    cp "../Dockerfile.caddy-cloudflare" ./Dockerfile
    cp "../docker-compose.caddy.yml" ./docker-compose.yml
    cp "../.env.example" ./.env.example
    cp "../caddy_cloudflare_deployment_fix.md" ./README.md
else
    print_error "Configuration files not found. Please ensure you have the corrected files in the parent directory."
    exit 1
fi

# Check for existing Caddyfile
if [ ! -f "./Caddyfile" ]; then
    print_warning "No Caddyfile found in current directory."
    
    if [ -f "../Uploads/Caddyfile" ]; then
        print_status "Found Caddyfile in ../Uploads/, copying..."
        cp "../Uploads/Caddyfile" ./Caddyfile
    else
        print_status "Creating sample Caddyfile..."
        cat > ./Caddyfile << 'EOF'
{
    # Global configuration
    acme_dns cloudflare {env.CLOUDFLARE_API_TOKEN}
    
    # Optional: Use staging for testing
    # acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
}

# Example site configuration
# Replace with your actual domain and service
example.com {
    reverse_proxy app:8080
}

# Health check endpoint
localhost:80 {
    respond "Caddy is running!"
}
EOF
        print_warning "Created sample Caddyfile. Please edit it with your actual domains and services."
    fi
fi

# Setup environment file
if [ ! -f "./.env" ]; then
    print_status "Setting up environment file..."
    cp .env.example .env
    
    print_warning "Please edit the .env file with your Cloudflare API token:"
    echo "  1. Get your token from: https://dash.cloudflare.com/profile/api-tokens"
    echo "  2. Edit .env file: nano .env"
    echo "  3. Set CLOUDFLARE_API_TOKEN=your_token_here"
    echo ""
    
    read -p "Press Enter after you've configured the .env file, or 's' to skip: " -r
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        print_warning "Skipping .env configuration. Remember to configure it before starting services."
    else
        # Open editor
        if command_exists nano; then
            nano .env
        elif command_exists vim; then
            vim .env
        else
            print_warning "No editor found. Please manually edit the .env file."
        fi
    fi
else
    print_status "Found existing .env file"
fi

# Check if API token is configured
if grep -q "your_cloudflare_api_token_here" .env 2>/dev/null; then
    print_warning "Cloudflare API token appears to be unconfigured in .env file"
fi

# Pull Docker images
print_status "Pulling Docker images..."
docker compose pull

# Create networks and volumes
print_status "Creating Docker networks and volumes..."
docker compose up --no-start

# Set proper permissions for volumes
print_status "Setting up volume permissions..."
sudo chown -R 1000:1000 "$(docker volume inspect caddy_data -f '{{.Mountpoint}}')" 2>/dev/null || true
sudo chown -R 1000:1000 "$(docker volume inspect caddy_config -f '{{.Mountpoint}}')" 2>/dev/null || true

# Validate Caddyfile
print_status "Validating Caddyfile configuration..."
if docker compose run --rm caddy caddy validate --config /etc/caddy/Caddyfile; then
    print_success "Caddyfile validation passed"
else
    print_error "Caddyfile validation failed. Please check your configuration."
    print_status "You can manually validate with: docker compose run --rm caddy caddy validate --config /etc/caddy/Caddyfile"
    read -p "Continue anyway? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Start services
print_status "Starting Caddy services..."
docker compose up -d

# Wait a moment for startup
sleep 5

# Check service health
print_status "Checking service status..."
if docker compose ps | grep -q "Up"; then
    print_success "Caddy is running successfully!"
    
    # Show container status
    echo ""
    print_status "Container status:"
    docker compose ps
    
    echo ""
    print_status "To view logs: docker compose logs -f"
    print_status "To restart: docker compose restart"
    print_status "To stop: docker compose down"
    
    # Test local connectivity
    echo ""
    print_status "Testing local connectivity..."
    if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200\|301\|302"; then
        print_success "Local HTTP connectivity test passed"
    else
        print_warning "Local HTTP connectivity test failed - this may be normal if you don't have localhost configured"
    fi
    
else
    print_error "Some services failed to start properly"
    echo ""
    print_status "Container status:"
    docker compose ps
    echo ""
    print_status "Logs:"
    docker compose logs --tail=20
fi

# Final instructions
echo ""
print_success "Setup completed!"
echo ""
echo "Next steps:"
echo "1. Verify your domains point to this server's IP"
echo "2. Check logs: docker compose logs -f caddy"
echo "3. Test HTTPS: curl -I https://your-domain.com"
echo "4. Monitor certificate issuance in the logs"
echo ""
echo "Troubleshooting:"
echo "- Configuration validation: docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile"
echo "- Reload configuration: docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile"
echo "- View detailed logs: docker compose logs -f"
echo ""
echo "Files created in: $INSTALL_DIR"
echo "- Caddyfile (edit for your domains)"
echo "- docker-compose.yml (service configuration)"
echo "- .env (environment variables)"
echo "- README.md (detailed documentation)"

print_status "Setup script completed!"
