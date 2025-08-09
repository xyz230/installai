#!/bin/bash
set -e

# === CONFIGURAZIONE ===
DOMAIN="catmi.it"
APP_DIR="/var/www/catmi"
NGINX_CONFIG="/etc/nginx/sites-available/catmi"
SSL_EMAIL="admin@catmi.it"
GIT_REPO="https://github.com/TUA-ORG/catmi.git" # <-- CAMBIA con URL reale

# === COLORI ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# === FUNZIONI ===
print_status()   { echo -e "${GREEN}✅ $1${NC}"; }
print_warning()  { echo -e "${YELLOW}⚠️ $1${NC}"; }
print_error()    { echo -e "${RED}❌ $1${NC}"; }
print_info()     { echo -e "${BLUE}ℹ️ $1${NC}"; }
command_exists() { command -v "$1" >/dev/null 2>&1; }

# === CONTROLLO UTENTE ===
if [[ $EUID -eq 0 ]]; then
   print_error "Non eseguire questo script come root. Usa un utente con sudo."
   exit 1
fi

echo -e "${BLUE}🐱 Benvenuto nell'installer di CatMi!${NC}"

# === AGGIORNAMENTO SISTEMA ===
print_info "Aggiornamento sistema..."
sudo apt update && sudo apt upgrade -y
print_status "Sistema aggiornato"

# === DIPENDENZE BASE ===
print_info "Installazione dipendenze base..."
sudo apt install -y curl wget git vim htop ufw software-properties-common apt-transport-https ca-certificates gnupg lsb-release unzip
print_status "Dipendenze base installate"

# === NGINX ===
print_info "Installazione Nginx..."
if ! command_exists nginx; then
    sudo apt install -y nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx
    print_status "Nginx installato"
else
    print_warning "Nginx già installato"
fi

# === CERTBOT ===
print_info "Installazione Certbot..."
sudo apt install -y certbot python3-certbot-nginx
print_status "Certbot installato"

# === NODE.JS & PM2 ===
print_info "Installazione Node.js e PM2..."
if ! command_exists node; then
    sudo apt remove -y nodejs libnode-dev npm || true
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
fi
sudo npm install -g pm2
print_status "Node.js e PM2 installati"

# === CLONAZIONE PROGETTO ===
print_info "Clonazione progetto..."
if [ ! -d "$APP_DIR" ]; then
    sudo git clone "$GIT_REPO" "$APP_DIR"
    sudo chown -R $USER:$USER "$APP_DIR"
else
    print_warning "Cartella già presente, skip clonazione"
fi

# === DIPENDENZE NPM ===
print_info "Installazione dipendenze npm..."
cd "$APP_DIR"
npm install
print_status "Dipendenze npm installate"

# === CONFIGURAZIONE NGINX ===
print_info "Configurazione Nginx per $DOMAIN..."
sudo tee "$NGINX_CONFIG" > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    root $APP_DIR;
    index index.html index.htm;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF
sudo ln -sf "$NGINX_CONFIG" /etc/nginx/sites-enabled/catmi
sudo nginx -t && sudo systemctl reload nginx
print_status "Nginx configurato"

# === CERTIFICATO SSL ===
print_info "Generazione certificato SSL..."
sudo certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos -m "$SSL_EMAIL"
print_status "SSL installato"

# === AVVIO APP CON PM2 ===
print_info "Avvio app con PM2..."
pm2 start npm --name "catmi" -- run start
pm2 save
pm2 startup systemd -u $USER --hp $HOME
print_status "App avviata"

# === FIREWALL ===
print_info "Configurazione firewall..."
sudo ufw allow 'Nginx Full'
sudo ufw --force enable
print_status "Firewall configurato"

print_status "Installazione completata! 🎉"
