# 🖥️ El ordenador virtual del libro

> **Para qué sirve:** que lo que ves en el libro y lo que ves **tú** en la terminal sea **exactamente lo mismo**, da igual qué ordenador tengas.
>
> Tu `/etc/passwd` no es igual que el mío, tus logs son otros, tu `grep` puede ser de otra versión… Con este entorno todo eso queda fijado: arrancas un **Ubuntu 24.04 de usar y tirar** con los mismos ficheros que se usaron para generar las salidas del libro.

---

## 1 · ¿Qué es exactamente?

Una **imagen Docker** (`regex-lab`) que, al arrancarla, te da una terminal dentro de un Ubuntu 24.04 con:

- 👤 un usuario **`alumno`** (con `sudo` sin contraseña, es un laboratorio desechable),
- 🧪 el laboratorio ya preparado en `~/lab-regex` (los mismos `ips.txt`, `correos.txt`, `arbol/`…),
- 📄 **`/etc/passwd`, `/etc/group`, `/etc/os-release`, `/etc/fstab`, `/etc/shells`, `/etc/ssh/sshd_config`…** con el contenido que usa el libro,
- 📜 **`/var/log/syslog`, `auth.log`, `kern.log`, `dpkg.log`, `ufw.log`, `apache2/access.log`…** con el contenido que usa el libro (en las rutas **reales**, así que los comandos del libro funcionan **tal cual**, sin cambiar rutas),
- 🔧 las herramientas: `grep` 3.11, `sed`, `find`, `locate`, `less`, `man` (con `man grep` y `man 7 regex`), `vim` (`vi`, `ex`), `tree`, `nano`…

Es lo más parecido a "montar una máquina virtual" para este libro, con una diferencia técnica: un **contenedor** comparte el *kernel* con tu ordenador (no es una VM completa con su propio *kernel*). Para practicar `grep`, `sed`, `find` y compañía da exactamente igual, y arranca en un segundo y pesa mucho menos.

---

## 2 · Instalar Docker (una vez)

| Tu sistema | Cómo |
|---|---|
| **Ubuntu / Debian** | `sudo apt install docker.io` y luego `sudo usermod -aG docker $USER` (cierra sesión y vuelve a entrar para que surta efecto) |
| **Windows 10/11** | Instala [Docker Desktop](https://www.docker.com/products/docker-desktop/) (usa WSL 2). Ejecuta los comandos desde **Git Bash** o desde una terminal de **WSL** |
| **macOS** | Instala [Docker Desktop](https://www.docker.com/products/docker-desktop/) (o Colima/OrbStack) |

Comprueba que funciona: `docker run --rm hello-world`.

---

## 3 · Usarlo

```bash
# 1. Descarga la guía (si aún no lo has hecho)
git clone -b claude/que-puedo-hacer-834z1j https://github.com/TheBillBull/Guias-y-Herramientas.git
cd Guias-y-Herramientas/guias/regex-grep-lpic1/entorno-virtual

# 2. Construye la imagen (UNA vez; tarda unos minutos)
bash construir.sh

# 3. Entra en tu ordenador virtual
bash entrar.sh
```

Dentro verás algo así:

```text
  🧪 Laboratorio de expresiones regulares - Ubuntu 24.04
     Estás en ~/lab-regex. Escribe 'ls' para ver los ficheros.
     Si lo estropeas:  preparar-laboratorio   (lo deja como nuevo)

alumno@ubuntu-pc:~/lab-regex$
```

Y ya puedes seguir el libro **desde el capítulo 0, sin hacer el "Paso 1-2" del laboratorio**: ya está hecho. Para salir: `exit` (o `Ctrl`+`D`).

| Quiero… | Hago… |
|---|---|
| **Comprobar** que el entorno coincide con el libro | `bash entrar.sh comprobar` (desde fuera) o `comprobar-entorno` (dentro) |
| **Empezar de cero** el laboratorio sin salir | `preparar-laboratorio` (dentro) |
| **Empezar de cero** del todo | `exit` y `bash entrar.sh` (cada entrada crea un contenedor nuevo y limpio) |
| **Conservar** mis ficheros entre sesiones | arranca con `docker run -it --name mi-lab --hostname ubuntu-pc regex-lab` y, para volver, `docker start -ai mi-lab` |
| **Sacar** un fichero al ordenador real | (desde otra terminal, con el contenedor abierto) `docker cp CONTENEDOR:/home/alumno/lab-regex/fichero .` |
| **Borrar todo** | `docker rmi regex-lab` |

---

## 4 · ¿Qué es real y qué está simulado?

Un contenedor no tiene discos, red ni `systemd` "de verdad". Para que el libro funcione igual, algunas órdenes devuelven el **texto de ejemplo** del libro:

| Orden | En el entorno virtual |
|---|---|
| `grep`, `sed`, `find`, `locate`, `sort`, `cut`, `tr`, `wc`, `less`, `man`, `vi`/`ex`, `tee`, `xargs`, `diff`, `comm`… | **Reales** (Ubuntu 24.04) |
| `/etc/passwd`, `group`, `os-release`, `fstab`, `shells`, `services`, `crontab`, `login.defs`, `sshd_config`, `grub`, `netplan`; todos los logs de `/var/log` | **Ficheros reales con contenido de ejemplo** (el mismo del libro) |
| `/etc/hosts`, `/etc/hostname` | Los gestiona Docker al arrancar; un pequeño *script* los deja como en el libro (`ubuntu-pc`) |
| `ip a`, `df -h`, `ps aux`, `mount`, `lsblk`, `ss -tuln`, `last`, `free`, `lscpu`, `dmesg` | **Simulados**: imprimen la salida de ejemplo (`SIMULAR=0 ps aux` ejecuta el comando real, que mostrará el contenedor) |
| `journalctl` | **Simulación mínima** hecha a partir del `syslog` de ejemplo (`-u`, `-p`) |
| `sudo` | Funciona **sin contraseña** (para `updatedb` y los ejemplos con `tee`) |
| `uname -r`, kernel | Los de **tu** ordenador (el contenedor comparte kernel) |
| Idioma | `C.UTF-8` (por eso los mensajes salen en **inglés** y `[a-z]` no incluye letras con tilde); `en_US.UTF-8` y `es_ES.UTF-8` están generados para probar el capítulo 4 |

> 🔎 Lo que **no** se ha podido comprobar en una máquina real con `systemd` (por ejemplo, el comportamiento exacto de `journalctl` o `lastb`) está marcado en el libro como "no se muestra su salida".

---

## 5 · Cómo sabemos que las salidas del libro son las de este entorno

Todas las salidas del libro (más de 900 bloques «Resultado», en los 630 ejercicios y en las explicaciones) se generaron **ejecutando cada comando dentro de este contenedor**: un programa lee el texto fuente de cada capítulo, ejecuta cada bloque de comandos con `docker exec`, y pega la salida real. Los bloques con varias formas "equivalentes" se ejecutan todos y se comprueba que dan el **mismo** resultado.

Si quieres comprobar tú que tu entorno es idéntico, ejecuta:

```bash
bash entrar.sh comprobar
```

Compara los `/etc/*` y `/var/log/*` del entorno con la copia que trae el libro (suma de comprobación SHA-256) y vuelve a obtener algunas respuestas conocidas (por ejemplo, la versión numérica de `/etc/os-release` del ejercicio del profesor).

---

## 6 · Problemas frecuentes

| Síntoma | Solución |
|---|---|
| `permission denied ... /var/run/docker.sock` | Tu usuario no está en el grupo `docker`: `sudo usermod -aG docker $USER` y vuelve a iniciar sesión (o usa `sudo bash construir.sh`) |
| `toomanyrequests` / límite de descargas de Docker Hub | `construir.sh` lo detecta y reintenta con una copia de la imagen en `mirror.gcr.io`. A mano: `docker build --build-arg BASE=mirror.gcr.io/library/ubuntu:24.04 -f entorno-virtual/Dockerfile -t regex-lab ..` (desde esta carpeta) |
| `bad interpreter` / `^M` en Windows | El `git clone` ha convertido los saltos de línea a Windows. El repositorio trae un `.gitattributes` que lo evita; si ya clonaste, borra la carpeta y clona de nuevo |
| El build falla sin red | La construcción necesita internet (descarga Ubuntu y paquetes). Después, el uso es sin conexión |
| `docker: command not found` | Instala Docker (sección 2) |

---

## 7 · Otras formas de usarlo

- 🐧 **Directamente en tu Ubuntu** (sin Docker): el libro funciona igual con `laboratorio/preparar-laboratorio.sh`. Los ejercicios sobre los ficheros de `~/lab-regex` darán lo mismo; los que usan `/etc/passwd` o `/var/log` darán resultados **parecidos pero con tus datos** (o usa la copia `~/lab-regex/sistema/…`).
- ☁️ **GitHub Codespaces / VS Code Dev Containers:** el repositorio incluye `.devcontainer/regex-lab/devcontainer.json`, que arranca esta misma imagen. **No está probado** (no se ha podido ejecutar en un Codespace); si lo intentas y falla, usa los pasos de arriba en tu propio ordenador.
- 🪟 **Una máquina virtual completa (VirtualBox, Multipass, WSL…):** instala Docker dentro de ella y sigue esta guía tal cual. No se ha probado.

---

## 8 · Qué hay en esta carpeta

| Fichero | Para qué |
|---|---|
| `Dockerfile` | La receta de la imagen (Ubuntu 24.04 + herramientas + datos del libro) |
| `construir.sh` | Construye la imagen `regex-lab` (con reintento por `mirror.gcr.io`) |
| `entrar.sh` | Abre una terminal dentro (o `comprobar`) |
| `scripts/preparar-imagen.sh` | Instala los ficheros de ejemplo en `/etc` y `/var/log`, crea las órdenes simuladas |
| `scripts/comprobar-entorno` | La comprobación de la sección 5 |
| `scripts/entrada-laboratorio`, `scripts/aplicar-ficheros-vivos` | Arreglan `/etc/hosts` y `/etc/hostname` al arrancar |
| `scripts/bashrc-alumno` | Alias con color y mensaje de bienvenida |

---

⬅️ [Volver al índice de la guía](../README.md)
