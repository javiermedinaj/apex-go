#!/bin/bash
# ============================================================
# USER DATA SCRIPT - Ubuntu 22.04
# Solo instala: Go, Node.js/npm, Nginx
# El código se despliega desde el repo
# ============================================================
set -e
exec > >(tee /var/log/user-data.log) 2>&1

echo "=========================================="
echo "ForgeAI - Configurando servidor..."
echo "=========================================="

# ============================================================
# 1. INSTALAR DEPENDENCIAS
# ============================================================
echo "📦 Instalando paquetes..."

apt-get update
apt-get install -y nginx golang-go curl git

# Instalar Node.js 20 y npm
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# ============================================================
# 2. CREAR DIRECTORIOS
# ============================================================
echo "📁 Creando directorios..."

mkdir -p /var/www/forgeai
mkdir -p /opt/middleware

# Permisos para ubuntu user
chown -R ubuntu:ubuntu /var/www/forgeai
chown -R ubuntu:ubuntu /opt/middleware

# ============================================================
# 3. CONFIGURAR NGINX
# ============================================================
echo "Configurando Nginx..."

cat > /etc/nginx/sites-available/forgeai << 'NGINX'
server {
    listen 80;
    server_name _;

    root /var/www/forgeai;
    index index.html;

    # Frontend estático
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Proxy al middleware Go
    location /api/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Health check
    location /health {
        proxy_pass http://127.0.0.1:8080;
    }
}
NGINX

# Activar sitio
ln -s /etc/nginx/sites-available/forgeai /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

systemctl enable nginx
systemctl restart nginx

# ============================================================
# 4. CONFIGURAR VARIABLES DE ENTORNO
# ============================================================
echo "⚙️ Configurando variables..."

cat >> /home/ubuntu/.bashrc << EOF

# ForgeAI Environment Variables
export SALESFORCE_INSTANCE_URL="${salesforce_instance_url}"
export SALESFORCE_ACCESS_TOKEN="${salesforce_access_token}"
EOF

echo "=========================================="
echo "✅ ForgeAI - Servidor listo!"
echo "=========================================="
# mostrar ip
IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "IP: $IP"
echo "Go: $(go version)"
echo "Node: $(node --version)"
echo "npm: $(npm --version)"
echo ""
echo "Directorios:"
echo "  Frontend: /var/www/forgeai/"
echo "  Middleware: /opt/middleware/"
echo "=========================================="
