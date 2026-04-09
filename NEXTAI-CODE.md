# NextAI Code - Project Configuration

<!-- auto-generated -->
## 1. Visión general del proyecto
Este repositorio es **infraestructura declarativa** para levantar un entorno multi-servicio con Docker Compose, más scripts de arranque en `scripts/` para inicialización y bootstrap.  
El foco del trabajo aquí no es lógica de aplicación, sino **orquestación, observabilidad, seguridad operativa e integración entre servicios** de forma reproducible.

## 2. Build & Development
Comandos reales y útiles para este repo (basado en `docker-compose.yml` y scripts shell existentes):

- **Build**
  - No hay `Dockerfile` ni pipeline de build propio en el repo.
  - La construcción/obtención de imágenes se gestiona con Compose:
```bash
docker compose pull
```

- **Run (stack completo o parcial)**
```bash
docker compose up -d
docker compose up -d mysql influxdb grafana
docker compose up -d elasticsearch kibana
```

- **Parada y limpieza**
```bash
docker compose stop
docker compose down
```
> Evitar `docker compose down -v` sin confirmación explícita (borra datos persistentes).

- **Inspección operativa**
```bash
docker compose ps
docker compose logs -f
docker compose logs -f elasticsearch
docker compose config
```

- **Test/Lint**
  - No existen comandos de test/lint definidos actualmente en el repositorio.
  - Validación mínima recomendada antes de commitear cambios en shell:
```bash
bash -n scripts/*.sh
```

## 3. Arquitectura y principios de diseño
- **Patrón arquitectónico actual**
  - Arquitectura de **orquestación por servicios** (Docker Compose) + **bootstrap procedural** (entrypoints shell).
  - No hay aún capas de dominio/aplicación en código fuente tradicional; el diseño está centrado en infraestructura.

- **Capas reales en este repo**
  - `docker-compose.yml`: topología y dependencias entre servicios.
  - `scripts/*-entrypoint.sh`: automatización de inicio/configuración por servicio.
  - `elasticsearch.yml`: configuración específica de Elasticsearch.
  - `.env`: contrato de variables de entorno.

- **Reglas de dependencia**
  - `scripts/` debe depender de variables de entorno y comandos del contenedor, **no** de rutas host frágiles.
  - `docker-compose.yml` referencia scripts montados en modo `:ro`; mantener ese patrón para evitar mutaciones en runtime.
  - Flujos de bootstrap deben ser **idempotentes** (especialmente `elastic-setup-entrypoint.sh`).
  - `filebeat-entrypoint.sh` existe, pero **no está conectado** en `docker-compose.yml` (no implementado aún como servicio).

- **SOLID aplicado a este stack**
  - **S (Single Responsibility):** un script por responsabilidad de arranque (ya reflejado en `scripts/`).
  - **O (Open/Closed):** extender comportamiento vía variables en `.env`, no hardcodeando valores en scripts.
  - **L (Liskov):** si se reemplaza una imagen/servicio, mantener contrato de healthcheck y entrypoint.
  - **I (Interface Segregation):** no mezclar bootstrap de múltiples servicios en un único script.
  - **D (Dependency Inversion):** scripts dependen de contratos externos (env vars/comandos), no de valores fijos.

- **Patrones relevantes**
  - **Entrypoint Pattern:** scripts como punto único de inicialización.
  - **Init/Setup one-shot:** servicio de setup dedicado para tareas post-arranque.
  - **Healthcheck-driven startup:** dependencia por estado saludable, no por orden de arranque ciego.

## 4. Estándares de calidad de código
- **Convenciones de nombres**
  - Scripts: `kebab-case` + sufijo `-entrypoint.sh` (como ya está en `scripts/`).
  - Variables de entorno: `UPPER_SNAKE_CASE`.
  - En Compose: nombres de servicio claros y estables; evitar renombrados innecesarios.

- **Organización de archivos**
  - Toda lógica de arranque debe residir en `scripts/`.
  - Configuración declarativa en raíz (`docker-compose.yml`, `elasticsearch.yml`).
  - Evitar duplicar configuración en múltiples sitios si ya existe en `.env`.

- **Patrones de manejo de errores (Shell)**
  - Scripts `sh`: iniciar con `set -eu`.
  - Scripts `bash`: `set -euo pipefail`.
  - Validar variables requeridas al inicio:
```sh
: "${ELASTIC_PASSWORD:?ELASTIC_PASSWORD no definida}"
```
  - Usar reintentos con backoff para llamadas de red (curl/API) en lugar de sleeps fijos.

- **Logging**
  - Logs estructurados simples por prefijo de script:
```sh
log() { echo "[elastic-setup] $*"; }
```
  - Mensajes accionables: qué falló, contra qué endpoint/comando, y siguiente paso.
  - No imprimir secretos ni tokens.

- **Orden recomendado en scripts**
  1. Shebang + opciones de shell  
  2. Validación de variables de entorno  
  3. Funciones auxiliares (`log`, `retry`, etc.)  
  4. Flujo principal (`main`)  

- **Orden recomendado en `docker-compose.yml`**
  - Mantener un orden consistente por servicio: `image`, `container_name`, `environment`, `volumes`, `depends_on`, `healthcheck`, `networks`, `restart`, `entrypoint`.

## 5. Estrategia de testing
Actualmente no hay suite de tests versionada. Estrategia recomendada para este tipo de repo:

- **Pirámide de pruebas (infraestructura + scripts)**
  1. **Validación estática (rápida):**
     - `docker compose config`
     - `bash -n scripts/*.sh`
  2. **Pruebas unitarias de scripts (a adoptar):**
     - Framework recomendado: **bats-core**.
     - Mockear comandos externos (`curl`, `influx`, etc.) para validar ramas de error/reintento.
  3. **Pruebas de integración (Compose):**
     - Levantar servicios clave y verificar healthchecks/ready state.
     - Validar que flujos de setup terminan correctamente.
  4. **Smoke tests operativos:**
     - Comprobación de logs de arranque, conectividad entre servicios y persistencia en volúmenes.

- **Qué mockear / qué no**
  - **Mockear** en unit tests de shell: CLI externas y respuestas HTTP.
  - **No mockear** en integración: red Docker, dependencias reales y healthchecks.

- **Convención de nombres de tests (propuesta)**
  - `test_<script>__<escenario>.bats`
  - Ejemplo: `test_elastic_setup__reintenta_hasta_disponible.bats`

- **Cobertura esperada (propuesta)**
  - Scripts críticos de bootstrap: alta cobertura de ramas de éxito/fallo.
  - Compose: cobertura funcional por escenarios (arranque limpio, reinicio, dependencia no disponible).

## 6. Buenas prácticas de seguridad
- **OWASP aplicado al contexto de este repo**
  - **A01 Broken Access Control:** minimizar uso de cuentas privilegiadas en herramientas administrativas.
  - **A02 Cryptographic Failures:** no asumir red interna como segura; en entornos no locales, exigir TLS y claves fuera del YAML.
  - **A03 Injection:** blindar scripts contra command injection (siempre comillas en variables, validar formato).
  - **A05 Security Misconfiguration:** revisar cambios en capacidades elevadas, `network_mode` y exposición de servicios.
  - **A06 Vulnerable Components:** escaneo periódico de imágenes y actualización controlada.
  - **A09 Security Logging and Monitoring Failures:** mantener trazabilidad clara de bootstrap y errores.

- **Validación de entradas en scripts**
  - Validar presencia y formato de env vars antes de uso.
  - Nunca interpolar variables sin comillas en comandos shell.

- **Gestión de secretos**
  - `.env` debe tratarse como sensible (no incluir valores reales en commits).
  - Mover secretos hardcodeados de YAML a variables de entorno cuando sea posible.
  - Rotar credenciales tras cambios de personal o exposición accidental.

- **Gestión de vulnerabilidades**
  - Incorporar escaneo de imágenes (Trivy/Grype) en CI.
  - Automatizar PRs de actualización de imágenes (Dependabot/Renovate para Compose).

## 7. Guías de rendimiento
- Evitar loops de espera agresivos en scripts; usar retry con backoff para no saturar CPU/API.
- Revisar impactos de servicios de monitorización/seguridad sobre el host (captura de red y scraping frecuente pueden degradar rendimiento).
- Mantener healthchecks equilibrados: muy frecuentes generan ruido; muy laxos retrasan detección.
- Priorizar persistencia en volúmenes para evitar recomputación/reinicialización costosa tras reinicios.
- En consultas de paneles/series temporales, limitar granularidad y ventanas de tiempo por defecto para no sobrecargar almacenamiento.
- La optimización de consultas de aplicación (ORM/driver) está **no implementada aún** en este repositorio (no hay código de aplicación versionado aquí).

<!-- user section -->
## 8. Comportamiento esperado de la IA
- **Antes de modificar**
  - Leer completo `docker-compose.yml` y los scripts afectados en `scripts/`.
  - Identificar impacto en dependencias (`depends_on`, healthchecks, redes y volúmenes).
  - Confirmar si el cambio afecta datos persistentes o seguridad operativa.

- **Al implementar cambios**
  - Mantener idempotencia en scripts de entrypoint/setup.
  - No introducir bashismos en scripts ejecutados con `/bin/sh`.
  - Preservar montajes `:ro` y principio de mínimo privilegio.

- **Revisión y validación mínima**
  - Ejecutar:
```bash
docker compose config
bash -n scripts/*.sh
```
  - Si el cambio es de orquestación, validar arranque parcial del servicio impactado y revisar logs.

- **Límites: pedir confirmación antes de**
  - Cambiar credenciales/secrets en `.env` o valores sensibles en YAML.
  - Ejecutar comandos destructivos de datos (`down -v`, borrado de volúmenes).
  - Modificar políticas de red/capacidades privilegiadas (`network_mode`, `cap_add`, permisos elevados).
  - Añadir nuevos servicios no existentes o exponer nuevos endpoints al host.

## 9. Notas
[Add project-specific notes, team conventions, or workflow preferences here]