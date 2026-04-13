# NextAI Code - Project Configuration

<!-- auto-generated -->
## 1. Project Overview
Este repositorio combina una aplicación PHP pequeña (`php/`) con una plataforma de observabilidad y seguridad desplegada por Docker Compose (`docker-compose.yml`, `scripts/`, `suricata/`).  
La prioridad de ingeniería aquí es mantener **separada** la lógica de aplicación, la lógica de arranque de contenedores y la configuración de monitoreo/IDS.

## 2. Build & Development
Comandos operativos reales para este proyecto (basados en `docker-compose.yml` y servicios existentes):

- Levantar todo el entorno:
```bash
docker compose up -d
```

- Ver estado de servicios:
```bash
docker compose ps
```

- Ver logs (ejemplos útiles):
```bash
docker compose logs -f php
docker compose logs -f mysql
docker compose logs -f suricata
```

- Validar resolución de Compose antes de arrancar (muy recomendable):
```bash
docker compose config
```

- Actualizar imágenes:
```bash
docker compose pull
```

- Parar entorno:
```bash
docker compose down
```

- Parar y limpiar volúmenes (reset completo de datos):
```bash
docker compose down -v
```

- Re-ejecutar setup puntual de Elastic cuando haga falta:
```bash
docker compose run --rm elastic-setup
```

- Checks manuales alineados con healthchecks definidos:
```bash
docker compose exec mysql mysqladmin ping -h localhost -u root -p"$MYSQL_ROOT_PASSWORD"
docker compose exec influxdb influx ping
docker compose exec elasticsearch sh -c 'curl -s -u elastic:$ELASTIC_PASSWORD http://localhost:9200/_cluster/health'
```

**Build/Test/Lint declarados en repo:** actualmente **no existen comandos dedicados** en archivos de automatización. Si se agregan, documentarlos aquí y en `README.md`.

## 3. Architecture & Design Principles
### Patrón arquitectónico actual
- **Monolito PHP ligero** en `php/` (scripts web directos) + **arquitectura de servicios contenedorizados** para DB, observabilidad y seguridad.
- No hay capas de dominio/aplicación formalizadas todavía (no hay estructura tipo MVC/hexagonal explícita).

### Reglas de dependencia por carpeta
- `php/`:
  - Debe contener solo lógica de HTTP/autenticación/aplicación.
  - No debe contener lógica de orquestación Docker ni comandos de sistema.
- `scripts/`:
  - Solo bootstrap/entrypoint de contenedores.
  - No debe incluir lógica de negocio de la app web.
- `suricata/`:
  - Solo configuración IDS.
  - No incrustar secretos ni credenciales.
- `docker-compose.yml` y `elasticsearch.yml`:
  - Infraestructura declarativa; no usar para “parchear” lógica que debería vivir en `php/` o `scripts/`.

### SOLID aplicado a este repo (práctico)
- **S (Single Responsibility)**: mantener `php/login.php` centrado en login, `php/auth.php` en validación de sesión/acceso, `php/index.php` en respuesta/página.
- **O (Open/Closed)**: extender autenticación añadiendo funciones reutilizables en `php/auth.php`, evitando duplicar validaciones en cada archivo PHP.
- **D (Dependency Inversion, versión procedural)**: pasar conexión/estado como dependencia (parámetros) en lugar de crear conexiones repetidas dentro de cada bloque de código.

### Patrones relevantes aquí
- **Entrypoint Script Pattern** (`scripts/*.sh`): inicialización determinista de cada servicio.
- **Guard reutilizable de autenticación** (`php/auth.php`): punto único para exigir acceso.
- **Infrastructure as Code** (`docker-compose.yml`, `suricata/*.config`): cambios trazables por PR, nunca manuales en contenedor.

## 4. Code Quality Standards
### Convenciones de PHP en este proyecto
- Mantener nombres de archivos en minúscula como ya existe (`auth.php`, `login.php`, `index.php`).
- Funciones: `camelCase`; constantes: `UPPER_SNAKE_CASE`.
- Evitar “código suelto” repetido; extraer helpers en `php/auth.php` cuando aplique.
- Siempre inicializar sesión/cabeceras al inicio del script, antes de cualquier salida.

### Organización de archivos
- Dado que hoy hay pocos archivos en `php/`, priorizar **cohesión por responsabilidad** y evitar mezclar autenticación con rendering.
- En `scripts/`, un script por servicio (como ya está); conservar ese enfoque y no unificar scripts inconexos.

### Manejo de errores (PHP + shell)
- En PHP:
  - Capturar excepciones de DB (`PDOException`) y devolver mensajes genéricos al cliente.
  - Registrar detalle técnico en logs, no en HTML.
- En shell (`scripts/*.sh`):
  - Usar modo estricto y fallar rápido.
```sh
set -euo pipefail
```

### Logging
- Aplicación PHP: `error_log(...)` con contexto mínimo (evento, archivo, resultado), sin secretos.
- Contenedores: log a stdout/stderr (ya alineado al modelo Docker).
- No loguear tokens, passwords, ni contenido de `.env` o `.tmp-auth-cookie.txt`.

### Orden recomendado en PHP
```php
<?php
declare(strict_types=1);

require_once __DIR__ . '/auth.php';
// luego configuración/sesión
// luego lógica principal
```

## 5. Testing Strategy
Actualmente no hay suite de tests declarada; por ello se recomienda arrancar con una pirámide simple y realista para este stack.

### Pirámide propuesta
- **Base (unitaria, PHP):**
  - Validaciones de entrada.
  - Funciones de autenticación aislables.
- **Media (integración):**
  - Flujo PHP ↔ MySQL con contenedores activos.
  - Validar respuestas HTTP de `php/login.php` y `php/index.php`.
- **Alta (smoke/e2e):**
  - Levantar stack completo y verificar que login + navegación básica funciona.
  - Verificar que servicios críticos están healthy tras `docker compose up -d`.

### Mocking: qué sí y qué no
- **Sí mockear**: dependencias difíciles de controlar unitariamente (hora, generadores de tokens, wrappers de DB si se introducen).
- **No mockear** en integración: MySQL y comportamiento HTTP real de PHP en contenedor.

### Convención de nombres de tests (cuando se incorporen)
- Estilo descriptivo en español o inglés, pero consistente:
  - `testLoginRechazaCredencialesInvalidas`
  - `testAuthRedirigeSiNoHaySesion`

### Cobertura objetivo inicial
- Lógica de autenticación (`auth/login`): alta prioridad.
- Flujos críticos (login, control de acceso): cobertura funcional obligatoria.
- Scripts de arranque: al menos smoke tests de ejecución/exit code.

## 6. Security Best Practices
### OWASP enfocado a este repo
- **Injection**: en cualquier acceso a MySQL, usar consultas preparadas.
```php
$stmt = $pdo->prepare('SELECT id FROM users WHERE username = :u');
$stmt->execute(['u' => $username]);
```
- **Broken Authentication**: en `php/login.php` y `php/auth.php`, usar `password_hash/password_verify`, `session_regenerate_id(true)` tras login.
- **XSS**: escapar toda salida dinámica en `php/index.php` con `htmlspecialchars`.
- **CSRF**: si hay formularios de login/acciones, usar token CSRF en sesión.
- **Security Misconfiguration**: no exponer `.env`, no reutilizar `.tmp-auth-cookie.txt`, no dejar credenciales en texto en scripts.

### Validación de entrada
- Validar y normalizar con `filter_input`/regex y límites de longitud.
- Rechazar entradas inesperadas por defecto (allowlist).

### Autenticación/autorización
- Centralizar controles en `php/auth.php` para no duplicar reglas.
- Toda página protegida debe ejecutar guard al inicio.

### Gestión de secretos
- Mantener secretos solo en variables de entorno (`.env`), nunca hardcodeados.
- Rotar credenciales cuando se cambien flujos de auth o se comparta entorno.
- Revisar que `.gitignore` cubra artefactos sensibles temporales.

### Vulnerabilidades de dependencias e imágenes
- Revisar imágenes periódicamente con `docker compose pull` + escaneo de CVEs.
- No hacer merge de cambios en `docker-compose.yml`/`scripts/` sin revisión de seguridad.

## 7. Performance Guidelines
- En PHP, evitar reconexiones innecesarias a DB por request; reutilizar conexión por flujo cuando sea posible.
- Minimizar consultas repetidas en `login/auth`; seleccionar solo columnas necesarias.
- Añadir índices en MySQL para campos de búsqueda frecuentes (p. ej., usuario/email) cuando se definan tablas.
- Evitar logging excesivo en rutas de alto tráfico.
- En `scripts/*.sh`, usar reintentos con backoff (no bucles apretados) para esperar servicios.
- No hay capa de caché de aplicación implementada todavía; si aparece latencia en autenticación/lecturas repetidas, introducir caché de forma explícita y medible.

<!-- user section -->
## 8. AI Behavior
### Antes de modificar código
- Leer siempre los archivos afectados y su contraparte directa:
  - cambios en auth/login ⇒ revisar `php/auth.php`, `php/login.php`, `php/index.php`
  - cambios de arranque ⇒ revisar script correspondiente en `scripts/`
  - cambios de IDS ⇒ revisar archivos de `suricata/`
- Verificar impacto en ejecución con `docker compose config`.

### Expectativas de revisión y prueba
- Tras cambios funcionales en PHP:
  - levantar stack,
  - revisar logs de `php` y `mysql`,
  - probar flujo básico de autenticación.
- Tras cambios de infraestructura:
  - comprobar que servicios levantan y healthchecks convergen.

### Límites (no hacer sin preguntar)
- No cambiar secretos, claves, ni políticas de autenticación sin aprobación explícita.
- No alterar `network_mode` ni capacidades de seguridad de contenedores sin justificar riesgo/impacto.
- No introducir nuevas herramientas/frameworks de pruebas o lint sin acordar primero el estándar del equipo.

## 9. Notes
[Add project-specific notes, team conventions, or workflow preferences here]