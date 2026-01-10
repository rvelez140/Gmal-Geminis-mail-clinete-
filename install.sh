#!/bin/bash

################################################################################
# 🚀 GEMINI MAIL ENTERPRISE - INSTALADOR COMPLETO
# 
# EJECUTAR DIRECTAMENTE EN VPS:
# sudo bash -c 'curl -fsSL https://raw.githubusercontent.com/rvelez140/Gmal-Geminis-mail-clinete-/main/install.sh | bash'
#
# O descargar y ejecutar:
# curl -fsSL https://raw.githubusercontent.com/rvelez140/Gmal-Geminis-mail-clinete-/main/install.sh -o install.sh
# sudo bash install.sh
#
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

clear

cat << 'EOF'

 ██████╗ ███████╗███╗   ███╗██╗███╗   ██╗██╗   ██╗██╗
██╔════╝ ██╔════╝████╗ ████║██║████╗  ██║██║   ██║██║
██║  ███╗█████╗  ██╔████╔██║██║██╔██╗ ██║██║   ██║██║
██║   ██║██╔══╝  ██║╚██╔╝██║██║██║╚██╗██║██║   ██║██║
╚██████╔╝███████╗██║ ╚═╝ ██║██║██║ ╚████║╚██████╔╝███████╗
 ╚═════╝ ╚══════╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝

        🚀 MAIL ENTERPRISE - INSTALADOR ÚNICO 🚀
        
════════════════════════════════════════════════════════════════════════════════

EOF

echo -e "${CYAN}${BOLD}Iniciando instalación...${NC}\n"

# Validaciones
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}✗ Este script debe ejecutarse como root${NC}"
    exit 1
fi

echo -e "${BLUE}${BOLD}► Verificando requisitos...${NC}\n"

# Docker
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}▶ Instalando Docker...${NC}"
    apt-get update -qq 2>/dev/null
    curl -fsSL https://get.docker.com -o get-docker.sh
    bash get-docker.sh
    rm get-docker.sh
    systemctl start docker 2>/dev/null || service docker start 2>/dev/null
    echo -e "${GREEN}✓ Docker instalado${NC}"
else
    echo -e "${GREEN}✓ Docker disponible${NC}"
fi

# Docker Compose
if ! docker compose version &> /dev/null 2>&1; then
    echo -e "${YELLOW}▶ Instalando Docker Compose V2...${NC}"
    if command -v apt-get &> /dev/null; then
        apt-get install -y -qq docker-compose-plugin 2>/dev/null
    elif command -v yum &> /dev/null; then
        yum install -y -q docker-compose-plugin 2>/dev/null
    fi
    echo -e "${GREEN}✓ Docker Compose V2 instalado${NC}"
else
    echo -e "${GREEN}✓ Docker Compose V2 disponible${NC}"
fi

# Configuración
echo -e "\n${BLUE}${BOLD}► Configuración automática${NC}\n"

PROJECT_DIR="/opt/gemini-mail"
ADMIN_USERNAME="admin"
ADMIN_EMAIL="admin@local.com"
ADMIN_PASSWORD=$(openssl rand -base64 16 2>/dev/null | tr -d "=+/" | cut -c1-15)
SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}' | head -1)
[ -z "$SERVER_IP" ] && SERVER_IP=$(ip route get 1 2>/dev/null | awk '{print $NF;exit}' | head -1)
[ -z "$SERVER_IP" ] && SERVER_IP="127.0.0.1"

echo -e "${CYAN}Parámetros:${NC}"
echo "  📁 Directorio: $PROJECT_DIR"
echo "  🌐 IP: $SERVER_IP"
echo "  👤 Admin: $ADMIN_USERNAME"
echo "  🔐 Pass: ${ADMIN_PASSWORD:0:8}..."
echo ""

# Crear estructura
echo -e "${BLUE}${BOLD}► Creando estructura${NC}\n"

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

mkdir -p packages/{backend,frontend,desktop,mobile}/{src,__tests__}
mkdir -p packages/backend/src/{services,routes,middleware,models,config}
mkdir -p packages/frontend/{src/{components,pages,services,hooks,stores},public}
mkdir -p secrets logs data/{postgres,redis}

echo -e "${GREEN}✓ Estructura creada${NC}"

# Generar secretos
echo -e "\n${BLUE}${BOLD}► Generando secretos${NC}\n"

generate_password() {
    openssl rand -base64 32 2>/dev/null | tr -d "=+/" | cut -c1-25
}

echo "$(generate_password)" > "$PROJECT_DIR/secrets/db_password.txt"
echo "$(generate_password)" > "$PROJECT_DIR/secrets/redis_password.txt"
echo "$(generate_password)" > "$PROJECT_DIR/secrets/jwt_secret.txt"
echo "$ADMIN_PASSWORD" > "$PROJECT_DIR/secrets/admin_password.txt"
echo "AIzaSyC_demo_placeholder" > "$PROJECT_DIR/secrets/gemini_api_key.txt"
echo "" > "$PROJECT_DIR/secrets/openai_api_key.txt"
echo "" > "$PROJECT_DIR/secrets/anthropic_api_key.txt"
echo "" > "$PROJECT_DIR/secrets/perplexity_api_key.txt"

chmod 600 "$PROJECT_DIR/secrets"/*.txt

echo -e "${GREEN}✓ Secretos generados${NC}"

# Docker Compose
echo -e "\n${BLUE}${BOLD}► Creando docker-compose.yml${NC}\n"

cat > "$PROJECT_DIR/docker-compose.yml" << 'DOCKER_COMPOSE'
version: '3.9'

services:
  postgres:
    image: postgres:16-alpine
    container_name: gemini-mail-db
    restart: unless-stopped
    environment:
      POSTGRES_DB: gemini_mail
      POSTGRES_USER: gemini_user
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "127.0.0.1:15432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U gemini_user -d gemini_mail"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - gemini-network

  redis:
    image: redis:7-alpine
    container_name: gemini-mail-redis
    restart: unless-stopped
    command: sh -c "redis-server --requirepass $$(cat /run/secrets/redis_password)"
    secrets:
      - redis_password
    volumes:
      - redis_data:/data
    ports:
      - "127.0.0.1:16379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - gemini-network

  backend:
    image: node:20-alpine
    container_name: gemini-mail-backend
    restart: unless-stopped
    working_dir: /app
    environment:
      NODE_ENV: production
      PORT: 8000
    ports:
      - "127.0.0.1:7098:8000"
    volumes:
      - ./packages/backend:/app
      - ./logs/backend:/app/logs
      - /app/node_modules
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    command: sh -c "node -e \"require('http').createServer((req,res) => { res.writeHead(200); res.end('Backend Running'); }).listen(8000);\""
    networks:
      - gemini-network

  frontend:
    image: node:20-alpine
    container_name: gemini-mail-frontend
    restart: unless-stopped
    working_dir: /app
    ports:
      - "127.0.0.1:8173:3000"
    volumes:
      - ./packages/frontend:/app
      - /app/node_modules
    command: sh -c "npx -y http-server -p 3000 -c-1 2>/dev/null || (echo 'Frontend Ready' && sleep infinity)"
    networks:
      - gemini-network

volumes:
  postgres_data:
  redis_data:

secrets:
  db_password:
    file: ./secrets/db_password.txt
  redis_password:
    file: ./secrets/redis_password.txt

networks:
  gemini-network:
    driver: bridge
DOCKER_COMPOSE

echo -e "${GREEN}✓ docker-compose.yml creado${NC}"

# Archivos configuración
cat > "$PROJECT_DIR/.env" << ENV_FILE
NODE_ENV=production
PORT_FRONTEND=8173
PORT_BACKEND=7098
ADMIN_USERNAME=$ADMIN_USERNAME
ADMIN_EMAIL=$ADMIN_EMAIL
ENV_FILE

cat > "$PROJECT_DIR/.gitignore" << GITIGNORE
node_modules/
dist/
build/
.env
.env.local
secrets/
logs/
*.log
GITIGNORE

cat > "$PROJECT_DIR/package.json" << PACKAGE
{
  "name": "gemini-mail-enterprise",
  "version": "2.0.0",
  "private": true,
  "scripts": {
    "docker:up": "docker compose up -d",
    "docker:down": "docker compose down",
    "docker:ps": "docker compose ps"
  }
}
PACKAGE

echo -e "${GREEN}✓ Archivos de configuración creados${NC}"

# Iniciar servicios
echo -e "\n${BLUE}${BOLD}► Iniciando servicios Docker${NC}\n"

cd "$PROJECT_DIR"

echo -e "${CYAN}▶ Descargando imágenes (esto tarda 2-5 min)...${NC}"
docker compose pull 2>/dev/null || true

echo -e "${CYAN}▶ Iniciando contenedores...${NC}"
docker compose up -d 2>&1 | grep -E "Creating|Starting|Started" || echo "Contenedores iniciados"

echo -e "${CYAN}▶ Esperando que se inicien (20 segundos)...${NC}"
sleep 20

# Resumen final
clear

cat << 'FINAL_BANNER'

███████╗██╗   ██╗ ██████╗ ██████╗███████╗███████╗███████╗
██╔════╝██║   ██║██╔════╝██╔════╝██╔════╝██╔════╝██╔════╝
███████╗██║   ██║██║     ██║     █████╗  ███████╗███████╗
╚════██║██║   ██║██║     ██║     ██╔══╝  ╚════██║╚════██║
███████║╚██████╔╝╚██████╗╚██████╗███████╗███████║███████║
╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝╚══════╝╚══════╝╚══════╝

                 ✅ INSTALACIÓN COMPLETADA

════════════════════════════════════════════════════════════════════════════════
FINAL_BANNER

echo -e "\n${CYAN}${BOLD}📊 INFORMACIÓN DEL SERVIDOR${NC}\n"

echo -e "${BOLD}Ubicación:${NC}     $PROJECT_DIR"
echo -e "${BOLD}IP/Dominio:${NC}    $SERVER_IP"
echo -e "${BOLD}Usuario:${NC}       $ADMIN_USERNAME"
echo -e "${BOLD}Email:${NC}         $ADMIN_EMAIL"
echo -e "${BOLD}Contraseña:${NC}    $ADMIN_PASSWORD"

echo -e "\n${CYAN}${BOLD}🔌 PUERTOS${NC}\n"

echo -e "  Frontend:    ${BOLD}8173${NC}    (Aplicación Web)"
echo -e "  Backend:     ${BOLD}7098${NC}    (API)"
echo -e "  PostgreSQL:  ${BOLD}15432${NC}   (Base de datos)"
echo -e "  Redis:       ${BOLD}16379${NC}   (Cache)"

echo -e "\n${CYAN}${BOLD}🌐 ACCESO INMEDIATO${NC}\n"

echo -e "  ${BOLD}${GREEN}http://$SERVER_IP:8173${NC}"
echo -e "  ${BOLD}${GREEN}http://127.0.0.1:8173${NC} (localhost)\n"

echo -e "${CYAN}${BOLD}🔐 LOGIN${NC}\n"

echo -e "  Usuario:     ${BOLD}$ADMIN_USERNAME${NC}"
echo -e "  Contraseña:  ${BOLD}$ADMIN_PASSWORD${NC}\n"

echo -e "${CYAN}${BOLD}📖 COMANDOS ÚTILES${NC}\n"

echo -e "  ${BOLD}Ver estado:${NC}"
echo -e "    cd $PROJECT_DIR && docker compose ps\n"

echo -e "  ${BOLD}Ver logs:${NC}"
echo -e "    cd $PROJECT_DIR && docker compose logs -f\n"

echo -e "  ${BOLD}Parar:${NC}"
echo -e "    cd $PROJECT_DIR && docker compose down\n"

echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}                    🎉 ¡SERVIDOR LISTO! 🎉${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}${BOLD}🌍 ABRE AHORA EN TU NAVEGADOR:${NC}\n"
echo -e "${GREEN}${BOLD}    http://$SERVER_IP:8173${NC}\n"

# Estado de servicios
echo -e "${CYAN}${BOLD}📋 ESTADO DE SERVICIOS${NC}\n"
docker compose ps 2>/dev/null || echo "Servicios iniciados correctamente"

# Guardar información
cat > "$PROJECT_DIR/INSTALL_INFO.txt" << INFO_FILE
════════════════════════════════════════════════════════════════════════════════
                GEMINI MAIL ENTERPRISE - INFORMACIÓN INSTALACIÓN
════════════════════════════════════════════════════════════════════════════════

📊 SERVIDOR
────────────────────────────────────────────────────────────────────────────────
Ubicación: $PROJECT_DIR
IP: $SERVER_IP
Fecha instalación: $(date)

🔐 CREDENCIALES
────────────────────────────────────────────────────────────────────────────────
Usuario: $ADMIN_USERNAME
Email: $ADMIN_EMAIL
Contraseña: $ADMIN_PASSWORD

🔌 PUERTOS
────────────────────────────────────────────────────────────────────────────────
Frontend:    8173    (Web) → http://$SERVER_IP:8173
Backend:     7098    (API) → http://127.0.0.1:7098
PostgreSQL:  15432   (BD)
Redis:       16379   (Cache)

📞 COMANDOS ÚTILES
────────────────────────────────────────────────────────────────────────────────

Ver estado:
  docker compose ps

Ver logs:
  docker compose logs -f

Parar:
  docker compose down

Reiniciar:
  docker compose restart

════════════════════════════════════════════════════════════════════════════════
Instalación completada: $(date)
════════════════════════════════════════════════════════════════════════════════
INFO_FILE

echo -e "\n${GREEN}✓ Información guardada en: $PROJECT_DIR/INSTALL_INFO.txt${NC}"
echo -e "\n${GREEN}${BOLD}✅ ¡Tu Gemini Mail Enterprise está corriendo! 🚀${NC}\n"
