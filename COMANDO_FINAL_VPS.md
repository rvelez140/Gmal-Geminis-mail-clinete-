# 🚀 COMANDO CORRECTO - PARA TU VPS (ENERO 2026)

## ⚡ COPIAR Y PEGAR EN TU VPS

```bash
sudo bash -c 'curl -fsSL https://raw.githubusercontent.com/rvelez140/Gmal-Geminis-mail-clinete-/main/install.sh | bash'
```

---

## 📝 PASO A PASO

### 1️⃣ Conectar al VPS

```bash
ssh root@tu-vps-ip
# Ejemplo:
ssh root@192.168.100.50
```

### 2️⃣ Copiar y Pegar el Comando

```bash
sudo bash -c 'curl -fsSL https://raw.githubusercontent.com/rvelez140/Gmal-Geminis-mail-clinete-/main/install.sh | bash'
```

### 3️⃣ Presionar ENTER

**Espera 5-10 minutos** mientras se instala todo automáticamente

### 4️⃣ Abrir en Navegador

Al terminar verás:
```
🌐 ACCESO INMEDIATO

  http://192.168.100.50:8173
```

**Copia esa URL y pégala en tu navegador**

---

## 🎯 LO QUE EL COMANDO HACE

✓ Descarga el script de instalación desde GitHub  
✓ Lo ejecuta automáticamente con permisos root  
✓ Instala Docker (si no existe)  
✓ Instala Docker Compose V2  
✓ Crea estructura completa  
✓ Genera contraseñas seguras  
✓ Crea docker-compose.yml  
✓ Descarga imágenes Docker  
✓ Inicia 4 servicios:
  - PostgreSQL 16
  - Redis 7
  - Backend Node.js
  - Frontend React
✓ Muestra IP y credenciales
✓ Guarda información

---

## 📊 SALIDA ESPERADA

```
 ██████╗ ███████╗███╗   ███╗██╗███╗   ██╗██╗   ██╗██╗
██╔════╝ ██╔════╝████╗ ████║██║████╗  ██║██║   ██║██║
██║  ███╗█████╗  ██╔████╔██║██║██╔██╗ ██║██║   ██║██║
██║   ██║██╔══╝  ██║╚██╔╝██║██║██║╚██╗██║██║   ██║██║
╚██████╔╝███████╗██║ ╚═╝ ██║██║██║ ╚████║╚██████╔╝███████╗
 ╚═════╝ ╚══════╝╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝

                 ✅ INSTALACIÓN COMPLETADA

════════════════════════════════════════════════════════════════════════════════

📊 INFORMACIÓN DEL SERVIDOR

  Ubicación: /opt/gemini-mail
  IP: 192.168.100.50
  Usuario: admin
  Email: admin@local.com
  Contraseña: aBcD1234eFgH5678ijKl

🔌 PUERTOS

  Frontend: 8173 (Aplicación Web)
  Backend: 7098 (API)
  PostgreSQL: 15432 (Base de datos)
  Redis: 16379 (Cache)

🌐 ACCESO INMEDIATO

  ✓ http://192.168.100.50:8173
  ✓ http://127.0.0.1:8173 (localhost)

🔐 LOGIN

  Usuario: admin
  Contraseña: aBcD1234eFgH5678ijKl

════════════════════════════════════════════════════════════════════════════════
                    🎉 ¡SERVIDOR LISTO! 🎉
════════════════════════════════════════════════════════════════════════════════
```

---

## 🔐 CREDENCIALES

Se generan automáticamente:

- **Usuario:** admin
- **Email:** admin@local.com
- **Contraseña:** Aleatoria (mostrada en pantalla)
- **Ubicación:** `/opt/gemini-mail/INSTALL_INFO.txt`

---

## 📋 ALTERNATIVAS

### Si quieres descargar primero:

```bash
# Descargar
curl -fsSL https://raw.githubusercontent.com/rvelez140/Gmal-Geminis-mail-clinete-/main/install.sh -o install.sh

# Ejecutar
sudo bash install.sh
```

### Si prefieres desde directorio específico:

```bash
sudo bash -c 'cd /opt && curl -fsSL https://raw.githubusercontent.com/rvelez140/Gmal-Geminis-mail-clinete-/main/install.sh | bash'
```

---

## ✅ VERIFICAR DESPUÉS

```bash
# Ver estado de servicios
docker compose ps

# Ver logs
docker compose logs -f

# Ver información guardada
cat /opt/gemini-mail/INSTALL_INFO.txt

# Ver contraseña admin
cat /opt/gemini-mail/secrets/admin_password.txt
```

---

## 📞 COMANDOS ÚTILES

```bash
cd /opt/gemini-mail

# Ver estado
docker compose ps

# Ver logs en tiempo real
docker compose logs -f

# Parar servicios
docker compose down

# Reiniciar servicios
docker compose restart

# Agregar API Key Gemini
nano secrets/gemini_api_key.txt
# Editar y guardar
docker compose restart backend
```

---

## 🆘 SI ALGO FALLA

```bash
# Ver logs detallados
cd /opt/gemini-mail
docker compose logs

# Reiniciar todo
docker compose restart

# Ver estado completo
docker compose ps -a

# Si algo no funciona, reinicia todo
docker compose down -v
docker compose up -d
```

---

## ⏱️ TIEMPO ESTIMADO

| Paso | Duración |
|------|----------|
| Verificaciones | 1 min |
| Descargar imágenes | 2-5 min |
| Crear estructura | 30 seg |
| Iniciar servicios | 1-2 min |
| **TOTAL** | **5-10 minutos** |

---

## 📊 ESTRUCTURA CREADA

```
/opt/gemini-mail/
├── docker-compose.yml      (Orquestación)
├── .env                    (Variables)
├── .gitignore
├── package.json
├── secrets/                (Contraseñas seguras)
├── packages/
│   ├── backend/            (API Node.js)
│   └── frontend/           (Web App)
├── logs/                   (Logs de aplicación)
└── data/                   (Datos persistentes)
```

---

## 🎯 SERVICIOS INICIADOS

```
CONTAINER              IMAGE              STATUS
gemini-mail-db         postgres:16        Up (healthy)
gemini-mail-redis      redis:7            Up (healthy)
gemini-mail-backend    node:20-alpine     Up (healthy)
gemini-mail-frontend   node:20-alpine     Up (healthy)
```

---

## ✨ CARACTERÍSTICAS

✓ **Un solo comando** - Sin preguntas  
✓ **Detección automática de IP**  
✓ **Instala Docker si falta**  
✓ **Genera secretos seguros**  
✓ **Health checks automáticos**  
✓ **Production-ready**  
✓ **Todo guardado en INSTALL_INFO.txt**  

---

## 🌐 ACCEDER

**URL:** `http://TU_IP:8173`

**Credenciales:**
```
Usuario: admin
Contraseña: (La que mostró la instalación)
```

---

## 🎉 ¡LISTO!

**Solo necesitas:**

1. ✓ Conectar al VPS
2. ✓ Copiar el comando
3. ✓ Presionar ENTER
4. ✓ Esperar 5-10 minutos
5. ✓ Abrir http://IP:8173 en navegador

---

## 📌 EL COMANDO FINAL

```bash
sudo bash -c 'curl -fsSL https://raw.githubusercontent.com/rvelez140/Gmal-Geminis-mail-clinete-/main/install.sh | bash'
```

**Cópialo, pégalo en tu VPS y ¡listo! 🚀**

---

**¡Tu Gemini Mail Enterprise estará en producción en minutos!**
