# Agents + Ollama LLM Tests

Repositorio de laboratorio para evaluar **agentes de programación locales** sobre una tarea reproducible de Java 21, Spring Boot 3, JPA y Maven.

El objetivo no es comparar únicamente la calidad de una respuesta aislada del LLM. Se compara el sistema completo:

```text
modelo local
+ harness de agente
+ lectura y edición de archivos
+ terminal
+ Git
+ compilación
+ tests
+ diagnóstico y reparación
+ control de contexto
+ restricciones de seguridad
```

Los primeros harnesses del laboratorio son:

1. **OpenCode + Ollama**: candidato principal actual.
2. **Cline CLI + Ollama**: implementación ya probada; se conserva como referencia comparativa.

> **Estado actual:** el bootstrap de OpenCode está preparado en modo deliberadamente restrictivo y de solo lectura. Todavía falta seleccionar y configurar el modelo Ollama del portátil antes de ejecutar el benchmark.

**EN summary:** This repository benchmarks the whole coding-agent [harness], not merely the raw language model.

---

## 1. Inicio rápido: OpenCode

### 1.1. Entrar en el repositorio

```bash
cd /ruta/al/repositorio
pwd
ls -la
```

La raíz debe contener, como mínimo:

```text
AGENTS.md
BENCHMARK_TASK.md
opencode.jsonc
scripts/setup-opencode.mjs
scripts/run-opencode.mjs
```

Comprobación:

```bash
test -f AGENTS.md
 test -f BENCHMARK_TASK.md
 test -f opencode.jsonc
 test -f scripts/setup-opencode.mjs
 test -f scripts/run-opencode.mjs
```

> Los espacios iniciales de los cuatro últimos comandos no son necesarios; pueden ejecutarse sin ellos. Se muestran separados para facilitar la lectura.

**EN summary:** Always run the bootstrap from the repository root to keep the environment [hermetic].

### 1.2. Seleccionar Node 22 con NVM

El bootstrap exige Node.js 22.x.

```bash
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
nvm use 22.23.1
```

Comprobar versiones:

```bash
node --version
npm --version
```

Resultado esperado para Node:

```text
v22.23.1
```

Comprobación compacta:

```bash
node -p "process.version"
node -p "process.platform + ' ' + process.arch"
```

**EN summary:** Pinning Node reduces version [drift] between machines.

### 1.3. Primera instalación de OpenCode

Ejecutar una sola vez después de copiar el bootstrap al repositorio:

```bash
node scripts/setup-opencode.mjs
```

El script:

- crea o actualiza `package.json`;
- fija `opencode-ai` a la versión exacta `1.18.3`;
- genera `package-lock.json`;
- instala OpenCode en `node_modules/`;
- añade scripts NPM;
- añade `node_modules/` y `.opencode-runtime/` a `.gitignore`;
- verifica el binario local;
- no instala OpenCode globalmente.

Verificar inmediatamente:

```bash
npm run opencode:version
npm run opencode:paths
npm run opencode:config
git status --short
```

Archivos que deberían aparecer nuevos o modificados:

```text
package.json
package-lock.json
.gitignore
opencode.jsonc
scripts/setup-opencode.mjs
scripts/run-opencode.mjs
```

**EN summary:** The setup creates a pinned, project-local and [reproducible] OpenCode installation.

### 1.4. Instalación en clones o worktrees posteriores

Cuando `package.json` y `package-lock.json` ya estén versionados, usar:

```bash
npm ci
```

Después:

```bash
npm run opencode:version
npm run opencode:config
```

`npm ci` debe preferirse a `npm install` para reconstruir exactamente las dependencias fijadas por el lockfile.

**EN summary:** Use `npm ci` after cloning to preserve dependency [provenance].

---

## 2. Comandos actuales de OpenCode

Los scripts NPM se ejecutan siempre contra el binario local del repositorio.

### Mostrar versión

```bash
npm run opencode:version
```

Equivalente genérico:

```bash
npm run opencode -- --version
```

### Mostrar rutas efectivas

```bash
npm run opencode:paths
```

Equivalente:

```bash
npm run opencode -- debug paths
```

### Mostrar configuración efectiva

```bash
npm run opencode:config
```

Equivalente:

```bash
npm run opencode -- debug config
```

### Arrancar OpenCode

```bash
npm run opencode
```

No ejecutar todavía una tarea de código real hasta completar la configuración del modelo Ollama y revisar los permisos del paso 2.

### Pasar argumentos directamente

La forma general es:

```bash
npm run opencode -- <argumentos>
```

Ejemplos:

```bash
npm run opencode -- --version
npm run opencode -- debug paths
npm run opencode -- debug config
```

**EN summary:** NPM is the single entry point, which avoids accidentally invoking a global [binary].

---

## 3. Aislamiento de OpenCode

`scripts/run-opencode.mjs` crea y usa:

```text
.opencode-runtime/
├── config/
├── data/
├── cache/
└── state/
```

El launcher define estas variables para el proceso:

```text
OPENCODE_CONFIG=<repo>/opencode.jsonc
OPENCODE_DISABLE_CLAUDE_CODE=1
OPENCODE_DISABLE_LSP_DOWNLOAD=true
XDG_CONFIG_HOME=<repo>/.opencode-runtime/config
XDG_DATA_HOME=<repo>/.opencode-runtime/data
XDG_CACHE_HOME=<repo>/.opencode-runtime/cache
XDG_STATE_HOME=<repo>/.opencode-runtime/state
```

Esto reduce el uso accidental de configuración global del usuario.

### Reiniciar solamente el estado de OpenCode

```bash
rm -rf .opencode-runtime
```

El launcher recreará las carpetas en el siguiente arranque.

### Reinstalar las dependencias locales sin cambiar versiones

```bash
rm -rf node_modules
npm ci
```

### Reconstrucción completa de la instalación inicial

Usar solamente si el bootstrap o el lockfile necesitan regenerarse:

```bash
rm -rf node_modules package-lock.json
node scripts/setup-opencode.mjs
```

Antes de borrar el lockfile, revisar:

```bash
git diff -- package.json package-lock.json
```

**EN summary:** Runtime isolation makes clean reruns less [ambiguous] and easier to audit.

---

## 4. Política restrictiva inicial

`opencode.jsonc` comienza con:

- proveedor permitido: `ollama`;
- agente predeterminado: `plan`;
- profundidad de subagentes: `0`;
- lectura: permitida, excepto `.env`;
- búsqueda local: permitida;
- edición: denegada;
- shell: denegada;
- tareas/subagentes: denegados;
- skills: denegadas;
- LSP: denegado;
- web: denegada;
- directorios externos: denegados.

Comprobar la configuración real:

```bash
cat opencode.jsonc
npm run opencode:config
```

No se deben abrir permisos por comodidad. Cada permiso se habilitará cuando exista una necesidad concreta y una prueba que lo justifique.

**EN summary:** Capabilities will be granted incrementally to avoid a broad and [permissive] attack surface.

---

## 5. Ollama: comprobaciones previas

### Estado básico

```bash
ollama list
ollama ps
```

### Ver un modelo

```bash
ollama show ornith:35b-q4_K_M
ollama show ornith-cline-64k
ollama show ornith-cline-64k --parameters
```

### Ver modelos mediante la API local

```bash
curl -fsS http://127.0.0.1:11434/api/tags | jq
```

Solo nombres:

```bash
curl -fsS http://127.0.0.1:11434/api/tags \
  | jq -r '.models[]?.name'
```

### Verificar que el puerto está escuchando

```bash
ss -ltnp | grep 11434
```

### Logs del servicio

```bash
journalctl -u ollama -n 150 --no-pager
journalctl -u ollama -f
```

Filtro útil:

```bash
journalctl -u ollama -n 250 --no-pager \
  | grep -Ei 'error|timeout|num_ctx|context|prompt eval|eval time|offload|POST /api'
```

### GPU

```bash
nvidia-smi
watch -n 1 nvidia-smi
```

### Descargar o calentar un modelo

```bash
ollama pull <modelo>
ollama run <modelo>
```

No fijar todavía el modelo de OpenCode por intuición. Primero registrar la salida real de:

```bash
ollama list
ollama show <modelo-candidato>
```

**EN summary:** Inspect the actual Ollama inventory before selecting a model; avoid [speculative] configuration.

---

## 6. Alias y Modelfiles de Ollama

Los Modelfiles existentes están en:

```text
.ollama-modelfiles/
```

Modelos configurados por el script actual:

```text
ornith-cline-64k
qwen3-30b-direct
qwen3-coder-next-direct
```

### Crear los alias en el Ollama del PC configurado por defecto

```bash
cd .ollama-modelfiles
chmod +x configure-ollama-models.sh
./configure-ollama-models.sh
cd ..
```

El script usa por defecto:

```text
http://192.168.1.7:11434
```

### Crear los alias en Ollama local

```bash
cd .ollama-modelfiles
OLLAMA_HOST=http://127.0.0.1:11434 ./configure-ollama-models.sh
cd ..
```

### Verificar

```bash
ollama list | grep -E 'ornith-cline-64k|qwen3-30b-direct|qwen3-coder-next-direct'
ollama show ornith-cline-64k --parameters
```

> Un `num_ctx 65536` en el Modelfile expresa la configuración del alias, pero no garantiza que el harness use realmente 65536 tokens. La carga efectiva debe verificarse en logs.

**EN summary:** Model aliases are configuration [scaffolds], not proof of the context actually used by the client.

---

## 7. Reglas y tarea del benchmark

### Reglas permanentes

```text
AGENTS.md
```

Contiene:

- alcance y seguridad;
- prohibición de tocar fuera del repositorio;
- prohibición de instalar software;
- método de reparación;
- validación con Maven;
- política de Git.

### Tarea concreta

```text
BENCHMARK_TASK.md
```

Define:

- Java 21;
- Spring Boot 3;
- Maven;
- JPA/Hibernate;
- H2;
- entidades `Author` y `Book`;
- relación many-to-many bidireccional;
- repositorios, servicio y tests;
- `flush()` y `clear()` obligatorios;
- consulta real por ID;
- finalización únicamente con `BUILD SUCCESS`.

### Leer ambos ficheros desde terminal

```bash
sed -n '1,260p' AGENTS.md
sed -n '1,320p' BENCHMARK_TASK.md
```

### Preflight manual

```bash
java -version
javac -version
mvn -version
git status --short
```

Debe confirmarse Java 21 en los tres primeros comandos.

### Ejecutar tests manualmente

```bash
mvn test
```

Con más detalle:

```bash
mvn -e test
mvn -X test
```

Usar `-X` solo para diagnóstico: produce mucha salida y puede contaminar el contexto de un agente.

### Limpiar y probar

```bash
mvn clean test
```

### Ver los informes de tests

```bash
find target/surefire-reports -maxdepth 1 -type f -print
sed -n '1,240p' target/surefire-reports/*.txt
```

**EN summary:** The benchmark is intentionally strict so that a superficial success cannot masquerade as verified persistence.

---

## 8. Primera prueba de OpenCode: solo lectura

Este paso se hará después de configurar el modelo Ollama.

Prompt previsto:

```text
Read AGENTS.md and BENCHMARK_TASK.md completely.
Do not modify files.
Do not execute shell commands.
Summarize:
1. the objective,
2. the mandatory constraints,
3. the expected files,
4. the validation sequence,
5. the conditions for declaring success.
```

Antes de lanzarlo:

```bash
npm run opencode:version
npm run opencode:config
ollama list
ollama ps
git status --short
```

Después de la prueba:

```bash
git status --short
git diff --stat
git diff
```

El resultado correcto de esta fase es **cero cambios** en el repositorio.

**EN summary:** The read-only smoke test validates instruction following before granting any [agency].

---

## 9. Segunda fase prevista: agente de construcción limitado

Todavía no está implementada.

Permisos mínimos previstos:

- leer el repositorio;
- editar únicamente dentro del repositorio;
- ejecutar preflight de Java/Maven;
- ejecutar `mvn test`;
- consultar `git status` y `git diff`;
- prohibir `sudo`, `apt`, `curl`, `wget`, navegadores y rutas externas;
- prohibir subagentes al principio.

Comandos que el agente necesitará:

```bash
java -version
javac -version
mvn -version
mvn test
git status --short
git diff --stat
git diff
```

Comandos que seguirán prohibidos para el agente:

```text
sudo
apt
apt-get
snap
flatpak
curl
wget
rm sobre rutas externas
git push
git reset
git rebase
git merge
git switch
git checkout de otra rama
```

**EN summary:** The coding agent will receive the narrowest viable command set, avoiding dangerous [footguns].

---

## 10. Scripts NPM previstos para pasos posteriores

Estos nombres se reservan para el plan, pero **no existen todavía** en `package.json`:

```bash
npm run opencode:smoke
npm run opencode:benchmark
npm run opencode:diagnose
npm run opencode:reset
```

Uso previsto:

| Script | Objetivo futuro |
|---|---|
| `opencode:smoke` | prueba de lectura sin editar ni ejecutar shell |
| `opencode:benchmark` | ejecución completa del benchmark controlado |
| `opencode:diagnose` | versiones, rutas, config, Ollama y Java/Maven |
| `opencode:reset` | limpiar solamente el runtime aislado |

Hasta que se implementen, usar los comandos explícitos documentados en este README.

**EN summary:** Planned scripts are listed explicitly so future automation remains [deliberate], not ad hoc.

---

## 11. Git y worktrees

No ejecutar Cline y OpenCode simultáneamente sobre la misma carpeta.

### Ver worktrees

```bash
git worktree list
```

### Crear un worktree para OpenCode

Desde el repositorio principal:

```bash
git worktree add \
  ../agents-harness-benchmark/opencode \
  -b benchmark/opencode
```

### Crear uno para Cline

```bash
git worktree add \
  ../agents-harness-benchmark/cline-cli \
  -b benchmark/cline-cli
```

### Ver estado antes y después de una prueba

```bash
git status --short
git diff --stat
git diff
git log --oneline --decorate -10
```

### Crear un commit manual coherente

```bash
git status --short
git add <ficheros-relacionados>
git diff --cached
git commit -m "chore: add reproducible OpenCode bootstrap"
```

### Eliminar un worktree cuando ya no se necesite

```bash
git worktree remove ../agents-harness-benchmark/opencode
```

No usar `--force` sin revisar primero el estado del worktree.

**EN summary:** Separate worktrees prevent cross-agent [interference] while preserving a shared Git history.

---

## 12. Registro de una ejecución

Crear una carpeta de logs ignorada por Git o usar ficheros `*.log`, que ya están ignorados.

### Registrar un comando

```bash
npm run opencode 2>&1 \
  | tee "opencode-$(date '+%Y%m%d-%H%M%S').log"
```

### Registrar preflight

```bash
{
  date '+%d/%m/%Y %H:%M:%S %Z'
  node --version
  npm --version
  java -version
  javac -version
  mvn -version
  ollama list
  git status --short
} 2>&1 | tee "preflight-$(date '+%Y%m%d-%H%M%S').log"
```

### Medir duración

```bash
time npm run opencode
```

### Estado de Ollama en paralelo

```bash
journalctl -u ollama -f
```

En otra terminal:

```bash
watch -n 1 nvidia-smi
```

**EN summary:** Logs provide an auditable [chronicle] of latency, failures and model behavior.

---

## 13. Criterios de evaluación

Registrar, como mínimo:

1. Modelo y cuantización.
2. Equipo que ejecuta el harness.
3. Equipo que ejecuta Ollama.
4. Endpoint.
5. Contexto solicitado.
6. Contexto efectivo observado.
7. Tiempo hasta la primera respuesta.
8. Duración total.
9. Número de tool calls fallidas.
10. Reintentos.
11. Ficheros modificados.
12. Cumplimiento de `AGENTS.md`.
13. Cumplimiento estricto de `BENCHMARK_TASK.md`.
14. Resultado de `mvn test`.
15. Commits creados.
16. Intervenciones humanas necesarias.

Una ejecución solo puede considerarse éxito estricto cuando:

```text
BUILD SUCCESS
+ tests que conservan flush()/clear()
+ consulta real después de recargar
+ ausencia de requisitos debilitados
+ ausencia de cambios fuera del alcance
```

**EN summary:** Evaluation must distinguish a polished façade from a genuinely [sound] implementation.

---

## 14. Estructura relevante del repositorio

```text
.
├── README.md
├── AGENTS.md
├── BENCHMARK_TASK.md
├── opencode.jsonc
├── scripts/
│   ├── setup-opencode.mjs
│   └── run-opencode.mjs
├── .opencode-runtime/          # generado, ignorado
├── package.json                # generado por el bootstrap
├── package-lock.json           # generado por el bootstrap
├── node_modules/               # generado, ignorado
├── launch-cline.sh
├── .cline-config/
│   ├── global-settings.json
│   ├── models.json
│   └── providers.json
├── .cline-runtime/             # generado, ignorado
├── .cline-state/               # generado, ignorado
├── .clineignore
├── .ollama-modelfiles/
│   ├── configure-ollama-models.sh
│   ├── Modelfile.ornith-cline-64k
│   ├── Modelfile-qwen3-30b-direct
│   └── Modelfile-qwen3-coder-next-direct
└── cline-laptop-remote/
    ├── README.txt
    ├── agent-lab.conf
    ├── configure-ollama-lan.sh
    └── setup-cline-laptop.sh
```

**EN summary:** The layout keeps persistent configuration separate from disposable runtime [ephemera].

---

## 15. Incidencias conocidas del repositorio actual

### `notify-success.sh`

`BENCHMARK_TASK.md` exige:

```bash
./notify-success.sh
```

Pero el script no está incluido en el archivo ZIP actual. Antes de ejecutar el benchmark estricto debe añadirse y marcarse como ejecutable:

```bash
test -x ./notify-success.sh \
  || echo "PENDIENTE: falta notify-success.sh"
```

### `launch-cline-remote.sh`

`cline-laptop-remote/setup-cline-laptop.sh` intenta dar permisos a:

```text
launch-cline-remote.sh
```

Sin embargo, ese fichero tampoco está incluido en el ZIP actual. El flujo remoto de Cline está incompleto hasta añadirlo.

Comprobación:

```bash
test -f cline-laptop-remote/launch-cline-remote.sh \
  || echo "PENDIENTE: falta launch-cline-remote.sh"
```

### OpenCode todavía no tiene modelo configurado

El bootstrap solo prepara instalación, aislamiento y permisos de lectura. La configuración concreta de Ollama se añadirá después de revisar el portátil.

**EN summary:** These are explicit [caveats], not hidden assumptions.

---

# CLINE

Esta sección conserva de forma resumida el uso actual de Cline CLI para compararlo con OpenCode.

## C.1. Comprobar entorno

```bash
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
nvm use 22.23.1

cline --version
node --version
npm --version
java -version
javac -version
mvn -version
ollama list
```

Versión probada:

```text
Cline CLI 3.0.44
```

**EN summary:** Verify the complete toolchain before resuming a Cline trajectory.

## C.2. Ejecutar Cline en el equipo actual

Desde la raíz:

```bash
chmod +x launch-cline.sh
./launch-cline.sh
```

Guardando salida:

```bash
./launch-cline.sh 2>&1 \
  | tee "cline-$(date '+%Y%m%d-%H%M%S').log"
```

El launcher actual configura dentro del propio fichero:

```bash
MODEL="ornith-cline-64k"
OLLAMA_SERVER="LOCAL"
TASK_TIMEOUT_SECONDS=10800
RETRIES=20
NODE_VERSION="22.23.1"
```

Servidores admitidos por el `case`:

```text
LOCAL   http://127.0.0.1:11434
PC      http://192.168.1.7:11434
LAPTOP  http://192.168.1.9:11434
```

Para cambiar modelo o servidor, editar por ahora las variables de la cabecera de `launch-cline.sh`.

**EN summary:** The Cline launcher is usable, but its main parameters are still hard-coded rather than [parametric].

## C.3. Estado y configuración de Cline

Configuración base:

```text
.cline-config/
```

Configuración temporal:

```text
.cline-runtime/
```

Estado separado por servidor:

```text
.cline-state/local/
.cline-state/pc/
.cline-state/laptop/
```

Ver configuración:

```bash
find .cline-config -maxdepth 1 -type f -print -exec cat {} \;
```

Ver estado:

```bash
find .cline-state -maxdepth 3 -print 2>/dev/null
```

**EN summary:** Base configuration and mutable state are separated to improve test [repeatability].

## C.4. Reiniciar Cline

Solo runtime:

```bash
rm -rf .cline-runtime
```

Solo estado local:

```bash
rm -rf .cline-state/local
```

Solo estado del PC remoto:

```bash
rm -rf .cline-state/pc
```

Todo el estado:

```bash
rm -rf .cline-state
```

Cline recreará el directorio indicado por `--data-dir` cuando arranque.

**EN summary:** Reset the smallest necessary state to avoid erasing useful [breadcrumbs].

## C.5. Modelos de Cline

Crear alias:

```bash
cd .ollama-modelfiles
chmod +x configure-ollama-models.sh
./configure-ollama-models.sh
cd ..
```

En Ollama local:

```bash
cd .ollama-modelfiles
OLLAMA_HOST=http://127.0.0.1:11434 ./configure-ollama-models.sh
cd ..
```

Verificar:

```bash
ollama list
ollama show ornith-cline-64k --parameters
```

**EN summary:** Recreate aliases after modifying a Modelfile; editing the file alone has no effect.

## C.6. Cline en portátil usando Ollama remoto

Editar primero:

```bash
nano cline-laptop-remote/agent-lab.conf
```

En el PC que sirve Ollama:

```bash
cd cline-laptop-remote
chmod +x configure-ollama-lan.sh
./configure-ollama-lan.sh
```

En el portátil:

```bash
cd cline-laptop-remote
chmod +x setup-cline-laptop.sh
./setup-cline-laptop.sh
```

El último paso previsto sería:

```bash
./launch-cline-remote.sh
```

Pero ese launcher falta en el ZIP actual y debe añadirse antes de usar este flujo.

Comprobar conectividad desde el portátil:

```bash
curl -fsS http://192.168.1.7:11434/api/tags | jq
```

**EN summary:** Remote Ollama connectivity is designed, but the current laptop bundle is [incomplete].

## C.7. Diagnóstico de Cline y Ollama

```bash
journalctl -u ollama -f
```

En otra terminal:

```bash
./launch-cline.sh
```

Buscar contexto, timeout y peticiones:

```bash
journalctl -u ollama -n 300 --no-pager \
  | grep -Ei 'num_ctx|context|timeout|POST /api/chat|prompt eval|eval time|error'
```

Comprobar proceso real:

```bash
type -a cline
which -a cline
cline --version
```

Con NVM:

```bash
node -p "require('$(npm root -g)/cline/package.json').version"
```

**EN summary:** Correlate Cline output with Ollama logs to avoid a misleading [diagnosis].

## C.8. Limitaciones confirmadas de la prueba de Cline

- Se observó un corte exacto alrededor de 30 segundos en determinadas llamadas a Ollama.
- El `timeout: 600000` persistido no eliminó ese corte interno.
- El alias Ornith solicita 65536 tokens, pero Cline CLI 3.0.44 cargó 32768 en las pruebas observadas.
- El portátil ejecutando Ornith 35B localmente no resultó viable para el prefill del agente.
- El portátil usando Ollama remoto en el PC sí consiguió progresar.
- Una tarea fresca fue más efectiva que continuar una trayectoria larga y degradada.
- `BUILD SUCCESS` no basta si el agente ha debilitado `flush()`, `clear()` o la recarga real de datos.

Por estas razones, OpenCode se probará con:

- estado limpio;
- contexto inicial contenido;
- permisos mínimos;
- una única tarea;
- medición explícita de tiempos y herramientas;
- validación estricta del benchmark.

**EN summary:** Cline demonstrated useful autonomy, but timeout and context behavior made the workflow [brittle].

---

## Licencia y uso

Este repositorio es un laboratorio privado de evaluación. No almacenar secretos, tokens, credenciales ni datos personales en prompts, logs o archivos de runtime.

Comprobar antes de cada commit:

```bash
git status --short
git diff --check
git diff --cached
```

**EN summary:** Treat agent logs as potentially sensitive engineering [artefacts].
