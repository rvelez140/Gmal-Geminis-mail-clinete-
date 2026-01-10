# Gemini Mail Enterprise

🚀 **Sistema de correo empresarial completo basado en Gemini AI**

Instancia en producción con Docker en VPS en minutos.

## 📦 Características

- ✓ Backend Node.js/Express completo
- ✓ Frontend React con UI moderna
- ✓ PostgreSQL 16 para datos
- ✓ Redis 7 para caché
- ✓ Gemini AI integrado
- ✓ API RESTful
- ✓ Autenticación JWT
- ✓ Docker Compose listo
- ✓ Secrets management
- ✓ Health checks automáticos

## 🚀 Instalación Rápida

### Con Docker Compose (Recomendado)

```bash
git clone https://github.com/tu-usuario/gemini-mail-enterprise.git
cd gemini-mail-enterprise
sudo bash install-vps.sh
```

### O con un comando

```bash
sudo bash -c 'curl -fsSL https://raw.githubusercontent.com/tu-usuario/gemini-mail-enterprise/main/install-vps.sh | bash'
```

## 🌐 Acceso

Después de instalar:

```
URL: http://tu-vps-ip:8173
Usuario: admin
Contraseña: (mostrada en pantalla)
```

## 📊 Estructura

```
gemini-mail-enterprise/
├── packages/
│   ├── backend/           # API Node.js
│   ├── frontend/          # App React
│   ├── desktop/           # App Electron
│   └── mobile/            # App React Native
├── infrastructure/
│   ├── docker/            # Dockerfiles
│   └── nginx/             # Config Nginx
├── docs/                  # Documentación
├── scripts/               # Scripts útiles
├── tests/                 # Tests
├── docker-compose.yml     # Orquestación
├── .env.example           # Variables ejemplo
├── install-vps.sh         # Script instalación
└── README.md              # Este archivo
```

## 🔧 Comandos

```bash
# Iniciar servicios
docker compose up -d

# Ver logs
docker compose logs -f

# Ver estado
docker compose ps

# Parar servicios
docker compose down

# Reiniciar
docker compose restart

# Ver secretos
cat secrets/admin_password.txt
```

## 📖 Documentación

- [Guía de Instalación](docs/INSTALLATION.md)
- [Configuración](docs/CONFIGURATION.md)
- [API Reference](docs/API.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## 🔐 Seguridad

- Contraseñas generadas aleatoriamente
- Secretos en archivos separados (permisos 600)
- JWT para autenticación
- PostgreSQL con contraseña
- Redis con contraseña
- CORS configurado
- Input validation

## 📋 Requisitos

- Docker 20.10+
- Docker Compose 2.0+
- Ubuntu/Debian/CentOS
- 2GB RAM mínimo
- 5GB espacio disco

## 🐳 Servicios Docker

| Servicio | Puerto | Imagen |
|----------|--------|--------|
| Frontend | 8173 | node:20-alpine |
| Backend | 7098 | node:20-alpine |
| PostgreSQL | 15432 | postgres:16-alpine |
| Redis | 16379 | redis:7-alpine |

## 💾 Datos Persistentes

```
/opt/gemini-mail/
├── data/postgres/       # Base de datos
├── data/redis/          # Cache
└── logs/                # Logs de aplicación
```

## 🔄 Variables de Entorno

```
NODE_ENV=production
PORT_FRONTEND=8173
PORT_BACKEND=7098
PORT_POSTGRES=15432
PORT_REDIS=16379
ADMIN_USERNAME=admin
ADMIN_EMAIL=admin@local.com
```

## 🎯 API Endpoints

```
GET  /api/health              # Health check
POST /api/auth/login          # Login
POST /api/auth/logout         # Logout
GET  /api/user/profile        # Perfil usuario
GET  /api/emails              # Listar emails
POST /api/emails              # Enviar email
GET  /api/emails/:id          # Obtener email
```

## 🤝 Contribución

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea rama feature (`git checkout -b feature/AmazingFeature`)
3. Commit cambios (`git commit -m 'Add AmazingFeature'`)
4. Push a rama (`git push origin feature/AmazingFeature`)
5. Abre Pull Request

## 📄 Licencia

MIT License - ver LICENSE.md

## 📞 Soporte

- 📧 Email: support@gemini-mail.com
- 💬 Issues: GitHub Issues
- 📚 Wiki: GitHub Wiki

## 🙏 Agradecimientos

- Gemini AI por la API
- Docker por la containerización
- Node.js y React communities

---

**Desarrollado con ❤️ para facilitar la instalación de Gemini Mail Enterprise**

Última actualización: Enero 2026
