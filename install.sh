#!/bin/bash

# CatMi - Script di Installazione Automatica per Ubuntu 22.04
# Questo script installa tutto il necessario per far funzionare CatMi su una VPS Ubuntu 22.04

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Domain configuration
DOMAIN="catmi.it"
APP_DIR="/var/www/catmi"
NGINX_CONFIG="/etc/nginx/sites-available/catmi"
SSL_EMAIL="admin@catmi.it"  # Cambia con la tua email per Let's Encrypt

echo -e "${BLUE}🐱 Benvenuto nell'installer di CatMi!${NC}"
echo -e "${BLUE}Questo script installerà tutto il necessario per far funzionare CatMi su Ubuntu 22.04${NC}"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}❌ Non eseguire questo script come root. Usa un utente con privilegi sudo.${NC}" 
   exit 1
fi

# Function to print status
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo -e "${BLUE}🔄 Aggiornamento del sistema...${NC}"
sudo apt update && sudo apt upgrade -y
print_status "Sistema aggiornato"

echo -e "${BLUE}🔧 Installazione delle dipendenze di base...${NC}"
sudo apt install -y curl wget git vim htop ufw software-properties-common apt-transport-https ca-certificates gnupg lsb-release unzip
print_status "Dipendenze di base installate"

# Install Nginx
echo -e "${BLUE}🌐 Installazione di Nginx...${NC}"
if ! command_exists nginx; then
    sudo apt install -y nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx
    print_status "Nginx installato e avviato"
else
    print_warning "Nginx già installato"
fi

# Install Certbot for SSL
echo -
