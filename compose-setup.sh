#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Color definitions for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Starting Open WebUI + NGINX HTTPS Setup...${NC}\n"

# Safety Checks
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if user can run docker without sudo
if ! docker ps &> /dev/null; then
    echo -e "${RED}Error: Cannot run Docker. Make sure the Docker daemon is running and your user is in the 'docker' group (no sudo required).${NC}"
    exit 1
fi

# Check for Docker Compose
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
elif docker-compose version &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo -e "${RED}Error: Docker Compose is not installed.${NC}"
    exit 1
fi

# Check for OpenSSL
if ! command -v openssl &> /dev/null; then
    echo -e "${RED}Error: openssl is not installed. Please install openssl to generate certificates.${NC}"
    exit 1
fi

echo -e "${GREEN}Prerequisites met!${NC}\n"

# Directory Setup
echo -e "${YELLOW}Setting up directory structure...${NC}"
mkdir -p data
mkdir -p nginx/ssl
mkdir -p nginx/conf.d
echo -e "${GREEN}Directories created.${NC}\n"

# Generate Self-Signed Certificates
echo -e "${YELLOW}Generating self-signed SSL certificates...${NC}"
if [ ! -f nginx/ssl/cert.pem ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout nginx/ssl/key.pem \
        -out nginx/ssl/cert.pem \
        -subj "/C=US/ST=Local/L=Local/O=OpenWebUI/CN=localhost" 2>/dev/null
    echo -e "${GREEN}Certificates generated in ./nginx/ssl/${NC}\n"
else
    echo -e "${GREEN}Certificates already exist. Skipping...${NC}\n"
fi

# Create NGINX Configuration
echo -e "${YELLOW}Generating NGINX configuration...${NC}"
cat << 'EOF' > nginx/conf.d/default.conf
upstream openwebui {
    server open-webui:8080;
    keepalive 128;
    keepalive_timeout 1800s;
    keepalive_requests 10000;
}

server {
    listen 443 ssl;
    http2 on;
    server_name _; # Catch-all
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    gzip on;
    gzip_types text/plain text/css application/javascript image/svg+xml;
    location /api/ {
        proxy_pass http://openwebui;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        gzip off;
        proxy_buffering off;
        proxy_request_buffering off;
        proxy_cache off;
        tcp_nodelay on;
        add_header X-Accel-Buffering "no" always;
        add_header Cache-Control "no-store" always;
        proxy_connect_timeout 1800;
        proxy_send_timeout 1800;
        proxy_read_timeout 1800;
    }
    location ~ ^/(ws/|socket\.io/) {
        proxy_pass http://openwebui;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        gzip off;
        proxy_buffering off;
        proxy_cache off;
        proxy_connect_timeout 86400;
        proxy_send_timeout 86400;
        proxy_read_timeout 86400;
    }
    location /static/ {
        proxy_pass http://openwebui;
        proxy_buffering on;
        proxy_cache_valid 200 7d;
        add_header Cache-Control "public, max-age=604800, immutable";
    }
    location / {
        proxy_pass http://openwebui;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
server {
    listen 80;
    server_name _;
    return 301 https://$host$request_uri;
}
EOF
echo -e "${GREEN}NGINX configuration created.${NC}\n"

# Create Docker Compose File
echo -e "${YELLOW}Generating docker-compose.yml...${NC}"
cat << EOF > docker-compose.yml
services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:slim
    container_name: open-webui
    restart: unless-stopped
    extra_hosts:
      - "host.docker.internal:host-gateway"
    volumes:
      - ./data:/app/backend/data
    environment:
      - AUDIO_TTS_ENGINE=openai
      - AUDIO_TTS_OPENAI_API_BASE_URL=http://tts:5050/v1
      - AUDIO_TTS_MODEL=tts-1
      - AUDIO_TTS_VOICE=alloy

  nginx:
    image: nginx:alpine
    container_name: open-webui-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
    depends_on:
      - open-webui

  tts:
    image: travisvn/openai-edge-tts:latest
    container_name: tts
    environment: 
      - REQUIRE_API_KEY=False
EOF
echo -e "${GREEN}docker-compose.yml created.${NC}\n"

# Start the Stack
echo -e "${YELLOW}Starting Docker Compose stack...${NC}"
$COMPOSE_CMD up -d
echo -e "\n${GREEN}======================================================================${NC}"
echo -e "${GREEN}                     DEPLOYMENT SUCCESSFUL!                           ${NC}"
echo -e "${GREEN}======================================================================${NC}"
echo -e "\nOpen WebUI is now running behind NGINX."
echo -e "You can access it securely via:"
echo -e "👉 ${YELLOW}https://<your-server-ip>${NC}"
echo -e "\n${RED}Note on Security Warnings:${NC}"
echo -e "Because we are using a self-signed certificate, your browser will show"
echo -e "a security warning. You can safely bypass this (e.g., in Chrome, click"
echo -e "'Advanced' -> 'Proceed to host')."
echo -e "\nTo view logs, run:"
echo -e "   ${YELLOW}$COMPOSE_CMD logs -f${NC}"
echo -e "\nTo stop and tear down the stack, ensure you are in this directory and run:"
echo -e "   ${YELLOW}$COMPOSE_CMD down${NC}"
echo -e "\nAll your Open WebUI data is saved locally in the ${YELLOW}./data${NC} directory."
