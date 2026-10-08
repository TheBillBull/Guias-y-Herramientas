# 🐧 Expresiones regulares y `grep` — de cero a *master* (LPIC-1)

> Una guía **paso a paso, como para un niño que ve una terminal por primera vez**, que termina con ejercicios de nivel experto. **630 ejercicios** con la solución escondida y la **salida real** de cada comando, más 38 preguntas tipo test de LPIC-1. Incluye un **ordenador virtual** (Docker) para que **tus salidas sean idénticas a las del libro**.

Los comandos de este libro que se pueden ejecutar sin interacción (la inmensa mayoría) **se ejecutaron de verdad** dentro del [ordenador virtual](entorno-virtual/README.md) (Ubuntu 24.04, GNU `grep` 3.11) y lo que ves como resultado es lo que salió, no lo que "debería" salir. Cuando algo falla o sorprende (y pasa a menudo), el libro lo cuenta. Solo hay dos clases de ejemplos que **no** se ejecutaron: los **interactivos** (`less`, `man`, `vi` a pantalla completa; de `vi` se verificaron sus órdenes `:s` y `:g` mediante `ex`) y los de `journalctl` (el diario de `systemd` no existe en un contenedor). Van en bloques sin "Resultado".

---

## 🚀 Empieza aquí

Hay **dos caminos**. Elige uno:

### 🐳 Camino A · El ordenador virtual (recomendado)

Un Ubuntu 24.04 "de usar y tirar" dentro de Docker, con **los mismos `/etc/passwd`, logs y `grep` que se usaron para escribir el libro**. Así **tu pantalla y el libro coinciden letra por letra** y puedes destrozar lo que quieras sin riesgo.

```bash
git clone -b claude/que-puedo-hacer-834z1j https://github.com/TheBillBull/Guias-y-Herramientas.git
cd Guias-y-Herramientas/guias/regex-grep-lpic1/entorno-virtual
bash construir.sh      # una sola vez (unos minutos; necesita Docker)
bash entrar.sh         # ¡dentro! ya estás en ~/lab-regex
```

Instalar Docker, qué es real y qué simulado, problemas frecuentes → [**entorno-virtual/README.md**](entorno-virtual/README.md).

### 🐧 Camino B · Directamente en tu Ubuntu

Necesitas un **Ubuntu** (o cualquier Linux con GNU `grep`) y una terminal (`Ctrl`+`Alt`+`T`).

```bash
# 1. Descarga la guía
cd ~
git clone -b claude/que-puedo-hacer-834z1j https://github.com/TheBillBull/Guias-y-Herramientas.git

# 2. Crea tu laboratorio de prácticas (ficheros de ejemplo, logs, etc.)
bash ~/Guias-y-Herramientas/guias/regex-grep-lpic1/laboratorio/preparar-laboratorio.sh

# 3. Entra y empieza
cd ~/lab-regex
ls
```

Los ejercicios con ficheros de `~/lab-regex` darán lo mismo que el libro; los que usan **tu** `/etc/passwd` o **tus** logs darán algo parecido pero con tus datos.

> 📝 La parte `-b claude/que-puedo-hacer-834z1j` elige la rama donde está la guía. Cuando esté en la rama principal bastará `git clone https://github.com/TheBillBull/Guias-y-Herramientas.git`.
>
> 🔁 Si estropeas el laboratorio (o quieres empezar de cero), **vuelve a ejecutar el paso 2**: lo deja como nuevo.

Luego sigue los capítulos **en orden**: cada uno se apoya en el anterior.

---

## 📚 Los capítulos

| # | Capítulo | Ejercicios | Qué aprenderás |
|---|---|---:|---|
| 0 | [Tu primera vez frente a una terminal](00-primeros-pasos.md) | 12 | Qué es una terminal, `pwd` `ls` `cd` `cat` `less`, tuberías, seguridad, montar el laboratorio |
| 1 | [Tu primer `grep`](01-primer-grep.md) | 30 | `grep palabra fichero`, `-i -n -c -v -l -r -e`, comillas, códigos de salida |
| 2 | [Comodines vs. expresiones regulares](02-comodines-vs-regex.md) | 15 | La gran confusión: `*` de la terminal contra `*` de `grep` |
| 3 | [El punto y las anclas](03-punto-y-anclas.md) | 33 | `.` `^` `$` `\`, líneas vacías, trampas (`\r`, espacios invisibles) |
| 4 | [Los corchetes `[ ]`](04-corchetes.md) | 37 | Listas, rangos, `[^…]`, clases POSIX, qué pasa dentro y fuera del corchete |
| 5 | [Repeticiones](05-repeticiones.md) | 38 | `*` `+` `?` `{n,m}`, **la coma**, voraz vs. perezoso |
| 6 | [Grupos, alternativas y memoria](06-grupos-alternancia.md) | 35 | `( )` `\|` `\1`, rangos de números, palíndromos |
| 7 | [Palabras y fronteras](07-palabras-y-fronteras.md) | 22 | `-w` `-x` `\b` `\<` `\>` `\w` `\s` |
| 8 | [BRE contra ERE](08-bre-vs-ere.md) | 19 | `grep`, `egrep`, `fgrep`, `-P`; **el tema estrella del examen** |
| 9 | [Todas las opciones de `grep`](09-opciones-de-grep.md) | 28 | `-o -A -B -C -m -q -s`, `--include`, binarios, **stdin/stdout/stderr** |
| 10 | [Los ficheros del sistema](10-ficheros-del-sistema.md) | 54 | `/etc/passwd`, `group`, `fstab`, `hosts`, `services`… ⭐ *Usuarios:grupo con GID ≥ 50* |
| 11 | [Los logs](11-logs.md) | 61 | `syslog`, `auth.log`, `ufw.log`, `dpkg.log`, Apache: fechas, IPs, rankings |
| 12 | [Reconocer formatos](12-formatos.md) | 47 | ⭐ IPv4, IPv6, correo, nombre de máquina, MAC, DNI, URL… |
| 13 | [Nivel master](13-nivel-master.md) | 39 | `grep -P`, `\K`, lookahead, ⭐ *versión numérica en un solo comando* |
| 14 | [`sed` y los filtros](14-sed-y-filtros.md) | 56 | Sustituir, reordenar, borrar; `cut` `sort` `uniq` `tr` `wc` |
| 15 | [`vi`, `less`, `find`, `locate`](15-vi-find-locate.md) | 34 | Regex fuera de `grep`; `find -regex`; `bash [[ =~ ]]` |
| 16 | [El jefe final](16-retos-finales.md) | 33 + 30 | 4 misiones de investigación, retos y mini-examen tipo test |
| 17 | [🚰 La fontanería: flujos, tuberías y redirecciones](17-tuberias-y-redirecciones.md) | 37 + 8 | `>` `>>` `2>` `2>&1` `<` `<<` `<<<`, `tee`, `xargs`, `$( )`, `<( )`, `&&` `\|\|`, códigos de salida de una tubería. **LPIC 103.4** *(léelo a partir del cap. 9)* |
| — | [📄 Chuleta de una página](chuleta.md) | | Todo resumido para repasar |

⭐ = los ejercicios propuestos por tu profesor, resueltos paso a paso:

| Enunciado | Dónde |
|---|---|
| Líneas que empiezan por `VERSION` de `/etc/os-release` | [Cap. 3, ej. 3.7](03-punto-y-anclas.md) |
| Solo la **versión numérica** de esas líneas | [Cap. 13, ej. 13.1](13-nivel-master.md) |
| Regex de una **IPv4** | [Cap. 12, ej. 12.3](12-formatos.md) |
| Regex de una **IPv6** | [Cap. 12, ej. 12.15](12-formatos.md) |
| Regex de una **cuenta de correo** | [Cap. 12, ej. 12.21](12-formatos.md) |
| **Nombre de máquina** con un nivel de subdominio y TLD de 3 letras | [Cap. 12, ej. 12.29](12-formatos.md) |
| Listado **`Usuarios:grupo`** con GID ≥ 50 | [Cap. 10, ej. 10.20](10-ficheros-del-sistema.md) |

---

## 🎚️ Cómo se hacen los ejercicios

Cada ejercicio tiene un nivel:

| Icono | Nivel |
|---|---|
| 🟢 | Fácil: aplicar lo que acabas de aprender |
| 🟡 | Medio: combinar dos o tres ideas |
| 🔴 | Difícil: hay que pensar un rato |
| ⚫ | Master: retos de verdad, a menudo en **un solo comando** |

Y la **solución está escondida** en un desplegable (`💡 Ver solución`). La técnica que funciona: **(1)** lee, **(2)** escribe tu intento, **(3)** ejecútalo, **(4)** si no sale, piensa por qué, **(5)** solo entonces mira.

En las soluciones, lo que sale entre **`« »`** es lo que `grep` ha considerado "coincidencia" (en tu terminal lo verás **en rojo**).

### 🎯 La filosofía: el mínimo número de comandos

Siempre que se puede, los ejercicios buscan **una sola orden**, aunque sea larga: `grep -c` en vez de `grep | wc -l`, `grep -oP '…\K…'` en vez de `grep | grep -o | cut`, etc. Pero también verás las versiones con varios comandos cuando son **más claras** (porque a veces lo sencillo es lo mejor).

---

## 🔬 Sobre los datos del libro

- Los ejercicios usan los ficheros **reales** de Ubuntu (`/etc/passwd`, `/var/log/syslog`…), con sus **rutas reales**.
- Pero **tu `/etc/passwd` no es igual que el mío**. Para que las salidas del libro sean siempre idénticas, se generaron con **copias de ejemplo** de esos ficheros, incluidas en `laboratorio/datos/sistema/`.
- 🐳 **En el ordenador virtual (Camino A)** esas copias *son* `/etc/passwd`, `/etc/group`, `/var/log/syslog`…: tu salida es **idéntica** a la del libro. Compruébalo con `bash entrar.sh comprobar`.
- 🐧 **En tu propio Ubuntu (Camino B)** tu salida será *parecida*, con otros usuarios, fechas o números. Si quieres que te salga **exactamente igual que en el libro**, usa la copia: `grep root ~/lab-regex/sistema/etc/passwd`.
- Otros ficheros de práctica (`ips.txt`, `correos.txt`, `palabras.txt`, `dominios.txt`…) son **idénticos** en los dos caminos.
- Algunos logs (`syslog`, `auth.log`, `ufw.log`, `dpkg.log`, `access.log`) son **sintéticos**: ficticios pero realistas.

### ⚠️ Versiones y diferencias que conviene saber

| Detalle | Comentario |
|---|---|
| **`grep` 3.11** (Ubuntu 24.04) | Las salidas se generaron con esta versión. En Ubuntu 22.04 (`grep` 3.7) casi todo es idéntico; los mensajes de error pueden diferir ligeramente. |
| **`[a-z]` y el idioma** | En `en_US.UTF-8`/`es_ES.UTF-8` el rango puede incluir letras con tilde; las salidas del libro se generaron en `C.UTF-8`. El [capítulo 4](04-corchetes.md) lo explica con pruebas. |
| **`egrep` / `fgrep`** | En otras distribuciones con `grep` ≥ 3.8 imprimen un aviso de "obsoleto"; en Ubuntu 24.04 no. |
| **Idioma de los mensajes** | El ordenador virtual usa `C.UTF-8`: los errores salen en inglés (`No such file or directory`). En un Ubuntu en español dirán «No existe el fichero o el directorio». |
| **`less`** | En Ubuntu 24.04 acepta regex extendidas (comprobado), pero depende de cómo se compile. |
| **`grep -P`** | Existe en GNU `grep` (Linux), no en el de macOS ni en BusyBox. Fuera del examen LPIC-1. |

---

## 🧭 Ruta de estudio sugerida

| Si tienes… | Haz esto |
|---|---|
| **Una semana** | Un capítulo al día (0–7), repasando el anterior. Fin de semana: 8, 9 y la chuleta. |
| **Un mes** | Capítulos 0–9 en dos semanas (los ejercicios 🟢🟡 de cada uno); semana 3: 10–12; semana 4: 13–16. |
| **Prisa por el examen LPIC-1** | Capítulos **2, 3, 4, 5, 6, 8, 9, 14, 15, 17** y el mini-examen del 16. Los capítulos 13 y 12 son "extra" (`-P` no entra). |

**Trucos para aprender:** haz los ejercicios **sin mirar**; vuelve a hacerlos días después; cuando una solución te sorprenda, **cámbiala** y mira qué se rompe; usa `man grep` y `man 7 regex` como libros de consulta.

---

## 🗺️ Mapa LPIC-1 (101-500 / 102-500)

| Objetivo | Capítulos |
|---|---|
| 103.1 Trabajar en la línea de comandos | 0, 1 |
| 103.2 Procesar flujos de texto con filtros | 9, 14 |
| 103.3 Gestión básica de ficheros (comodines) | 2 |
| **103.4 Flujos, tuberías y redirecciones** | 0, 9, **17** |
| **103.7 Buscar en ficheros con expresiones regulares** | **1–8, 10–13** |
| 103.8 Edición básica con `vi` | 15 |
| 104.7 Buscar ficheros (`find`, `locate`, `whereis`…) | 15 |
| Contexto práctico: 104.3 (`fstab`), 107.1 (usuarios), 108.2 (logs), 109.x (`hosts`, `services`) | 10, 11 |

---

## 📂 Contenido del repositorio

```text
guias/regex-grep-lpic1/
├── README.md                 ← este índice
├── 00-…17-*.md               ← los 18 capítulos
├── chuleta.md                ← resumen de una página
├── entorno-virtual/          ← el ordenador virtual (Docker)
│   ├── README.md             ← instalación, uso, qué es real y qué simulado
│   ├── Dockerfile
│   ├── construir.sh · entrar.sh
│   └── scripts/              ← preparación de la imagen y comprobación
└── laboratorio/
    ├── preparar-laboratorio.sh   ← crea ~/lab-regex (Camino B; la imagen lo usa también)
    └── datos/                    ← ficheros de práctica
        ├── *.txt, *.csv, *.conf, *.py
        ├── salidas/              ← salidas simuladas (ip a, df, ps…)
        └── sistema/              ← copia de ejemplo de /etc y /var/log
```

---

⬅️ [Volver al índice del repositorio](../../README.md)
