# 🔐 Permisos en Linux — de cero a *master* (LPIC-1)

> Una guía **paso a paso, como para un niño que ve `ls -l` por primera vez**, que termina con ejercicios de nivel experto. **188 ejercicios, series y retos** (más un mini-examen de **30 preguntas** tipo LPIC-1), con la **salida real** de cada comando, un **laboratorio** que se monta con un script y **cuatro herramientas** para convertir y diagnosticar permisos.

> 📄 **También en PDF** (para imprimir o compartir): [guía completa (152 págs.)](pdf/Guia-Permisos-Linux-LPIC1.pdf) · [manual del laboratorio (14 págs.)](pdf/Laboratorio-Permisos-LPIC1.pdf) · [chuleta (2 págs.)](pdf/Chuleta-Permisos-Linux.pdf)

Nació de una captura de pantalla como esta (`ls -l saludos.sh`, `ls -l /etc/shadow`, `ls -ld /tmp/`, `ls -ld /var/spool/cron/crontabs/`…) y de una pregunta: *«quiero entender `-rwxrwxr-x` nada más verlo, y entender qué es `777` o `4755`»*. Al terminar, lo harás.

```text
-rwxrwxr-x 1 alumno alumno 1015 Oct  9 16:16 cerve.sh
│└┬┘└┬┘└┬┘                                        └─ …y el 775 que significa
│ │  │  └─ otros: pueden leer y ejecutar (r-x = 5)
│ │  └─ grupo:   pueden leer, escribir y ejecutar (rwx = 7)
│ └─ dueño:      puede leer, escribir y ejecutar (rwx = 7)
└─ es un fichero normal
```

Los comandos de este libro **se ejecutaron de verdad** (Ubuntu 24.04, GNU coreutils 9.4, bash 5.2) con un usuario normal llamado `alumno`, y lo que ves como _Resultado_ es lo que salió. Cuando algo falla o sorprende (y pasa a menudo: el SGID que *desaparece en silencio*, el `chmod -w` que quita de menos, el `chown` que borra el SUID…), el libro lo cuenta. Solo hay unas pocas partes **no ejecutadas**, y están marcadas como tales (ver [más abajo](#-sobre-los-datos-del-libro-y-qué-no-se-ejecutó)).

---

## 🚀 Empieza aquí

Necesitas un **Ubuntu** (o cualquier Linux con GNU coreutils), una terminal (`Ctrl`+`Alt`+`T`) y un usuario que pueda usar `sudo`.

```bash
# 1. Descarga la guía
cd ~
git clone https://github.com/TheBillBull/Guias-y-Herramientas.git

# 2. Monta el laboratorio (crea ~/lab-permisos y los usuarios de práctica ana, beto y carla;
#    te pedirá tu contraseña de sudo y que confirmes)
bash ~/Guias-y-Herramientas/guias/permisos-linux-lpic1/laboratorio/preparar-laboratorio.sh

# 3. Instala las herramientas (opcional pero muy recomendado)
sudo install -m 755 ~/Guias-y-Herramientas/guias/permisos-linux-lpic1/herramientas/permisos    /usr/local/bin/
sudo install -m 755 ~/Guias-y-Herramientas/guias/permisos-linux-lpic1/herramientas/diagnostica /usr/local/bin/

# 4. Entra y empieza por el capítulo 0
cd ~/lab-permisos
```

> 🔁 Si estropeas el laboratorio, **vuelve a ejecutar el paso 2**: lo deja como nuevo. Y cuando termines: `bash …/preparar-laboratorio.sh --limpiar` lo **borra todo** (la carpeta, los usuarios `ana` `beto` `carla`, los grupos y el permiso de tu carpeta personal). Solo borra lo que él mismo creó.

Luego sigue los capítulos **en orden**: cada uno se apoya en el anterior.

---

## 📚 Los capítulos

| # | Capítulo | Ejercicios | Qué aprenderás |
|:-:|---|:-:|---|
| 00 | [Antes de empezar: quién eres, quién es cada uno y el laboratorio](00-primeros-pasos.md) | 8 | `whoami` `id` `groups`, `/etc/passwd`, `root`, `sudo -u`, el elenco ana·beto·carla, cómo probar "como otra persona" |
| 01 | [Leer `ls -l` de un vistazo](01-leer-ls-l.md) | 15 | Los 10 caracteres, tipos de fichero, columnas, `ls -ld`, `stat`. ⭐ **Tu captura, línea a línea** (incluido el `°`) |
| 02 | [`r`, `w`, `x` en los ficheros](02-r-w-x-en-ficheros.md) | 13 | Leer, modificar, ejecutar; `./script` frente a `bash script`; `x` sin `r`; binarios; `w` no es borrar |
| 03 | [`r`, `w`, `x` en los directorios](03-directorios.md) | 11 | ⭐ **El que casi todos entienden mal**: las 8 combinaciones medidas, buzón `-wx`, `namei -l`, borrar manda la carpeta |
| 04 | [¿Quién decide qué?](04-quien-decide.md) | 13 | El algoritmo (root → dueño → grupo → otros), paradojas, grupos principal/secundarios, `usermod -aG` y `newgrp` |
| 05 | [Octal, binario, decimal y letras](05-octal-binario-decimal.md) | 16 | ⭐ **755, 644, 4755 de un vistazo**: 4-2-1, conversiones rápidas, trampa del decimal, herramienta `permisos`, series de velocidad |
| 06 | [`chmod` simbólico](06-chmod-simbolico.md) | 15 | `u+x` `go-w` `a=r`, `g=u`, `X`, `-R`, `--reference`, y la trampa del "sin quién" (`chmod -w` + umask) |
| 07 | [`chmod` octal](07-chmod-octal.md) | 14 | Equivalencias, octal frente a simbólico, `chmod -R` sin romper nada (`find`, `X`), bits como `\|` y `& ~` |
| 08 | [`umask`](08-umask.md) | 16 | `666 & ~umask`, **no es una resta**, cómo cambiarla, dónde se configura (Ubuntu `0002`), qué comandos la obedecen |
| 09 | [`chown` y `chgrp`](09-chown-chgrp.md) | 14 | Quién puede cambiar qué, todas las sintaxis, `-R`, `--from`, huérfanos, casos reales (`sudo` deja ficheros de root) |
| 10 | [SUID, SGID y *sticky*](10-permisos-especiales.md) | 16 | ⭐ `s` `S` `t` `T`, `4755` `2775` `1777`; demostraciones reales; carpeta de equipo; auditoría con `find -perm` |
| 11 | [Los permisos en la vida real](11-permisos-en-la-vida-real.md) | 11 | Mapa del sistema (`/etc/shadow`, `/home`, `/tmp`, `/var/mail`…), qué pide cada comando, `sed -i`, enlaces duros y simbólicos, SSH |
| 12 | [Más allá de `rwx`](12-mas-alla-de-rwx.md) | 10 | `chattr +i/+a`, opciones de montaje, *capabilities*, ACL, AppArmor/SELinux, y el mapa de todas las "puertas" |
| 13 | [Diagnóstico y recetas](13-diagnostico-y-recetas.md) | 7 | El método de 7 pasos, `namei`, `diagnostica`, `strace`, casos reales, recetario y **retos de reparación** |
| 14 | [El jefe final](14-jefe-final.md) | 9 | Misión intranet con **autocomprobación**, auditoría de seguridad, reconstruir listados, velocidad y **mini-examen de 30 preguntas** |
| — | [📄 Chuleta de una página](chuleta.md) | | Todo resumido para repasar |

⭐ = lo que salía en tu captura de pantalla, explicado y reproducido:

| Lo que enseñaste | Dónde está |
|---|---|
| `ls -l cerve.sh` → `-rwxrwxr-x 1 alumno alumno 1015 …` | [Cap. 1 · 1.1](01-leer-ls-l.md) |
| `ls -l saludos.sh` → `-rwxr-x--x` (751) y por qué "otros" no pueden ejecutarlo | [Cap. 1 · 1.10](01-leer-ls-l.md) · [Cap. 2](02-r-w-x-en-ficheros.md) |
| `ls -l salario.sh °` → el error por el `°` | [Cap. 1 · 1.10 ②](01-leer-ls-l.md) |
| `ls -l /etc/shadow` (`-rw-r-----` root:shadow) y `/etc/passwd` (`r--` de otros) | [Cap. 1 · 1.10](01-leer-ls-l.md) · [Cap. 11](11-permisos-en-la-vida-real.md) |
| `ls -ld /tmp/` → `drwxrwxrwt` (1777) | [Cap. 1](01-leer-ls-l.md) · [Cap. 10 · sticky](10-permisos-especiales.md) |
| `sudo ls -ld /var/spool/cron/crontabs/` → `drwx-wx--T` (1730) | [Cap. 1](01-leer-ls-l.md) · [Cap. 3 · el buzón](03-directorios.md) · [Cap. 10 · recreado](10-permisos-especiales.md) |
| "¿qué es 777, 4755…?" y "convertir rápido" | [Cap. 5](05-octal-binario-decimal.md) · [Cap. 10](10-permisos-especiales.md) · [entrenador](herramientas/entrenador-conversion.html) |

---

## 🛠️ Las herramientas

En `herramientas/` y `laboratorio/`. Todas están **verificadas contra el comportamiento real del sistema** (miles de comparaciones automáticas).

| Herramienta | Para qué | Cómo se usa |
|---|---|---|
| **`permisos`** (script de Bash) | **Traduce** permisos: octal ⇄ letras ⇄ binario ⇄ decimal ⇄ hex; calcula `umask`; aplica expresiones de `chmod` | `permisos 755` · `permisos -rwsr-xr-x` · `permisos 644 g+w,o-r` · `permisos -u 027` · `permisos /etc/shadow` |
| **`diagnostica`** (script de Bash) | **¿Por qué `carla` no puede leer esto?** Recorre la ruta tramo a tramo con el algoritmo real y señala el bloqueo | `sudo diagnostica -u carla /ruta/al/fichero` |
| [**`calculadora-chmod.html`**](herramientas/calculadora-chmod.html) | Calculadora **visual**: casillas `r/w/x` + especiales, conversión en todas direcciones y calculadora de `umask` | ábrela en el navegador |
| [**`entrenador-conversion.html`**](herramientas/entrenador-conversion.html) | **Entrenador de velocidad**: preguntas aleatorias, pasos de cálculo, racha, tiempo medio y *sprint* de 60 s | ábrelo en el navegador |
| **`preparar-laboratorio.sh`** | Crea `~/lab-permisos`, los usuarios `ana` `beto` `carla` y los grupos `equipo` `soporte` | `bash preparar-laboratorio.sh [--sin-usuarios \| --solo-usuarios \| --limpiar]` |

---

## 🎚️ Cómo se hacen los ejercicios

| Icono | Nivel |
|---|---|
| 🟢 | Fácil: aplicar lo que acabas de aprender |
| 🟡 | Medio: combinar dos o tres ideas |
| 🔴 | Difícil: hay que pensar un rato |
| ⚫ | Master: preguntas de examen, trampas y retos |

La **solución está escondida** en un desplegable (`💡 Ver solución`). La técnica que funciona: **(1)** lee, **(2)** escribe tu intento, **(3)** ejecútalo en tu laboratorio, **(4)** si no sale, piensa por qué, **(5)** solo entonces mira. Los comandos se muestran de dos maneras: **bloque + _Resultado_** y **transcripción** (`$ comando` y debajo su salida).

### 🧪 La filosofía: probar como otra persona

Lo que distingue a esta guía: para entender un permiso **hay que ver cómo falla**. Por eso el laboratorio tiene **cuatro personas** y todo se prueba con `sudo -u ana …`, `sudo -u carla …`:

| Quién | Qué es | Grupos |
|---|---|---|
| 🧑‍🎓 **alumno** | **tú** | `alumno` |
| 👩 **ana** | compañera de equipo | `ana`, `equipo` |
| 👨 **beto** | de equipo y de soporte | `beto`, `equipo`, `soporte` |
| 👩‍🔧 **carla** | solo de soporte | `carla`, `soporte` |

---

## 🔬 Sobre los datos del libro (y qué no se ejecutó)

- **Entorno de las salidas:** Ubuntu 24.04, GNU coreutils 9.4, bash 5.2, sistema de ficheros ext4. Cada comando se tecleó en una **terminal real** del usuario `alumno` con `umask 0002` (la de Ubuntu); los `sudo -u usuario …` se ejecutaron **como ese usuario** (con el `umask 0022` que impone `sudo`).
- **Idioma:** las salidas están en inglés (`LANG=C.UTF-8`): `Permission denied`. En un Ubuntu en español verás *Permiso denegado*, y los meses de `ls -l` en minúscula (`oct`). La tabla de equivalencias está en el [capítulo 0](00-primeros-pasos.md).
- **Tus números serán otros:** los UID/GID (`1001`, `1005`…), los tamaños, las fechas y los inodos cambian de una máquina a otra. Lo que importa son los **nombres** y los **permisos**.
- **Tu `/etc/shadow`, tus SUID…** no serán idénticos a los del libro (los ejemplos de ficheros del sistema se tomaron de la máquina de generación).
- **Los tres scripts de la captura** (`cerve.sh`, `saludos.sh`, `salario.sh`) se recrean con el **mismo tamaño en bytes** (1015, 93 y 419), las mismas fechas y los mismos permisos que en tus `ls -l`.
- **Lo que NO se ejecutó** (está marcado en el texto como "no ejecutado"): las **ACL** (`setfacl`/`getfacl`, capítulo 12: faltaban las herramientas en el entorno de generación y **no entran en LPIC-1**), el mensaje de **SSH** sobre claves demasiado abiertas (capítulo 11: no había cliente `ssh`), y los comandos **interactivos** (`newgrp` a pantalla completa, `vi`…).
- **Una advertencia sincera sobre `sudo`:** en el generador, `sudo -u ana …` lo ejecuta un proceso con privilegios que cambia de usuario (`runuser`); el resultado de los **permisos** es el mismo que con `sudo` de verdad, pero el *aviso de contraseña* de `sudo` no aparece en las salidas.

---

## 🧭 Ruta de estudio sugerida

| Si tienes… | Haz esto |
|---|---|
| **Una semana** | Un capítulo y medio al día (0-10), con la chuleta al final. Practica el [entrenador](herramientas/entrenador-conversion.html) 5 min cada día. |
| **Un mes** | Semana 1: caps. 0-4 (lo conceptual). Semana 2: 5-8 (números, `chmod`, `umask`). Semana 3: 9-12. Semana 4: 13-14 y repetir los ⚫. |
| **Prisa por el examen LPIC-1** | Capítulos **1, 3, 4, 5, 6, 7, 8, 9, 10** y el **mini-examen del 14**. Los capítulos 11-13 son "vida real" (y lo preguntan en forma de casos). |

**Trucos para aprender:** haz los ejercicios **sin mirar**; vuelve a hacerlos días después; cuando una solución te sorprenda, **cámbiala** y mira qué se rompe; usa `man chmod`, `man 7 credentials` y `info coreutils 'File permissions'` como libros de consulta; y **comprueba siempre con otro usuario** (`sudo -u carla …`): *"que no pueda"* también se prueba.

---

## 🗺️ Mapa LPIC-1 (101-500 / 102-500)

| Objetivo | Capítulos |
|---|---|
| **104.5 Gestionar permisos y propiedad de ficheros** | **1-10** (el núcleo), 13, 14 |
| 104.6 Crear y cambiar enlaces duros y simbólicos | 11 (permisos de los enlaces) |
| 107.1 Gestionar cuentas de usuario y grupo y ficheros del sistema relacionados | 0, 4, 9 |
| **110.1 Tareas de administración de seguridad** (auditar SUID/SGID, `sudo`, `/etc/shadow`) | **10**, 11, 14 |
| 103.1 / 103.3 Línea de comandos y gestión básica de ficheros | 0, 1, 2, 3 |
| Extras de la vida real (LPIC-2 y más allá) | 12 (`chattr`, ACL, *capabilities*, MAC) |

---

## 📂 Contenido del repositorio

```text
guias/permisos-linux-lpic1/
├── README.md                    ← este índice
├── 00-…14-*.md                  ← los 15 capítulos
├── chuleta.md                   ← resumen de una página
├── pdf/                         ← la guía, el manual del laboratorio y la chuleta en PDF
├── laboratorio/
│   └── preparar-laboratorio.sh  ← crea ~/lab-permisos, usuarios y grupos (y --limpiar)
└── herramientas/
    ├── permisos                 ← traductor de permisos (Bash)
    ├── diagnostica              ← ¿por qué este usuario no puede? (Bash)
    ├── calculadora-chmod.html   ← calculadora visual
    └── entrenador-conversion.html ← entrenador de velocidad
```

---

⬅️ [Volver al índice del repositorio](../../README.md)
