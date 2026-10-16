# Capítulo 0 · Antes de empezar: quién eres, quién es cada uno y el laboratorio

> 🎯 **Objetivo:** entender *a quién* se le aplican los permisos (usuarios, grupos, `root`) y montar un laboratorio con varias "personas" para comprobar los permisos **de verdad**.
>
> 📘 **LPIC-1:** 104.5 (permisos y propiedad) · 107.1 (usuarios y grupos) · 103.1 (línea de comandos).
>
> 🧪 **Antes de empezar:** una terminal en un Ubuntu (`Ctrl`+`Alt`+`T`) y un usuario que pueda usar `sudo`.

---

## 0.1 · ¿Para qué sirven los permisos?

Imagina un **edificio de oficinas** con mucha gente dentro: tú, tus compañeros, el jefe, la limpiadora, un cartero… Si todas las puertas estuvieran abiertas para todos, cualquiera podría leer tu correo, tirar a la basura tus papeles o fotocopiar la nómina del jefe.

Linux es **multiusuario** desde el día uno: en el mismo ordenador conviven personas **y programas** (el servidor web, la base de datos, el reloj…), y cada uno es "alguien" distinto. Los **permisos** son el sistema de **llaves y cerraduras** que dice, para *cada* fichero y *cada* carpeta:

| Pregunta | La respuesta vive en… |
|---|---|
| 🧑 ¿**Quién es el dueño**? | el **propietario** (*owner*) |
| 👪 ¿**Qué grupo** tiene derechos especiales? | el **grupo** (*group*) |
| 🔑 ¿**Qué puede hacer** cada uno? | los **permisos** (*mode*): leer, escribir, ejecutar |

Toda la guía es una forma larga de contestar a esas tres preguntas. Y todo se ve de un vistazo con `ls -l`, que aprenderás a leer **como si fuera tu idioma** en el capítulo 1.

---

## 0.2 · ¿Quién soy? `whoami`, `id` y `groups`

Antes de hablar de permisos hay que saber **quién eres tú para el sistema**. Tres comandos:

```bash
whoami
id
groups
```

_Resultado:_

```text
alumno
uid=1001(alumno) gid=1001(alumno) groups=1001(alumno)
alumno
```

Cómo se lee `id`:

```text
uid=1001(alumno) gid=1001(alumno) groups=1001(alumno)
 │        │          │       │           └─ TODOS tus grupos (números y nombres)
 │        │          │       └───────────── el nombre de tu grupo principal
 │        │          └───────────────────── el número de tu grupo principal (GID)
 │        └──────────────────────────────── el nombre de tu usuario
 └───────────────────────────────────────── el número de tu usuario (UID)
```

- El sistema **no entiende de nombres**, solo de **números**: el `uid` y el `gid`. Los nombres (`alumno`) son una comodidad para los humanos.
- Tu **UID** puede ser distinto al de este libro (en una Ubuntu recién instalada, el primer usuario suele ser el **1000**). Da igual: los **nombres** son lo que importa.
- Todo usuario tiene **un grupo principal** (el que se le pone a los ficheros que crea) y puede tener **otros grupos secundarios**.

> 💡 En Ubuntu cada usuario nuevo recibe un grupo **propio** con su mismo nombre (aquí `alumno:alumno`). Se llama *User Private Group* y es la razón de que veas **`alumno alumno`** (usuario y grupo iguales) en casi todos tus `ls -l`.

---

## 0.3 · Usuarios y grupos: `/etc/passwd` y `/etc/group`

Linux guarda la lista de personas y grupos en dos ficheros de texto **que ya hemos visto en tu captura**:

```bash
getent passwd alumno
getent group alumno
```

_Resultado:_

```text
alumno:x:1001:1001:alumno LPIC:/home/alumno:/bin/bash
alumno:x:1001:
```

`getent` pregunta al sistema "dime la ficha de…" (y funciona aunque los usuarios vengan de LDAP, etc.). Es equivalente a `grep alumno /etc/passwd`. Las fichas:

```text
alumno:x:1001:1001:alumno LPIC:/home/alumno:/bin/bash
  │    │   │    │      │           │            └─ la shell (programa que te recibe al entrar)
  │    │   │    │      │           └─────────────── carpeta personal (HOME)
  │    │   │    │      └─────────────────────────── comentario (nombre completo, etc.)
  │    │   │    └────────────────────────────────── GID del grupo principal
  │    │   └─────────────────────────────────────── UID
  │    └─────────────────────────────────────────── "x" = la contraseña está en /etc/shadow
  └──────────────────────────────────────────────── nombre de usuario

alumno:x:1001:
  │    │   │   └─ miembros SECUNDARIOS del grupo (vacío: nadie más)
  │    │   └───── GID
  │    └───────── (contraseña de grupo, casi nunca se usa)
  └────────────── nombre del grupo
```

| Fichero | Contiene | Permisos típicos |
|---|---|---|
| `/etc/passwd` | usuarios (nombre, UID, GID principal, HOME, shell) | `-rw-r--r--` (**todos** pueden leerlo) |
| `/etc/shadow` | las **contraseñas cifradas** | `-rw-r-----` root:shadow (**nadie** que no sea root o `shadow`) |
| `/etc/group` | grupos y sus miembros | `-rw-r--r--` |
| `/etc/gshadow` | contraseñas de grupo | `-rw-r-----` |

> 🧠 **Por qué `passwd` es legible por todos pero `shadow` no:** `passwd` tiene que poder leerse para que `ls -l` traduzca "1001" a "alumno". Las contraseñas cifradas, en cambio, estuvieron en `passwd` hasta los años 90… y se descubrió que cualquiera podía copiarlas y adivinarlas. Por eso se movieron a `shadow`, con permisos mucho más cerrados. Verás **las dos** líneas (`passwd` y `shadow`) de tu captura dentro de un rato.

---

## 0.4 · `root`, el que lo puede todo

Hay un usuario especial: **`root`**, con **UID 0**. Para el sistema, "ser administrador" significa exactamente eso: tener el UID 0. `root` **se salta casi todos los permisos** (puede leer, escribir y borrar casi cualquier cosa), así que:

> ⚠️ **Trabaja siempre como usuario normal y pide ser `root` solo para el comando que lo necesite.** Un `rm -rf` equivocado como `root` puede destrozar el sistema; como usuario normal, los permisos te protegen.

La forma de pedirlo es **`sudo`** (*"superuser do"*): ejecuta **un solo comando** como otro usuario (por defecto `root`), pidiéndote **tu** contraseña.

```text
sudo  [-u usuario]  comando
  │       └─ "como este usuario" (si no lo pones: root)
  └───────── "ejecuta esto con otra identidad"
```

```text
$ id root
uid=0(root) gid=0(root) groups=0(root)
$ sudo id
uid=0(root) gid=0(root) groups=0(root)
$ sudo -u ana id
uid=1002(ana) gid=1002(ana) groups=1002(ana),1005(equipo)
```

La primera línea usa `id root` (preguntar por `root`, sin `sudo`). La segunda ejecuta `id` **siendo `root`**. La tercera, **siendo `ana`**. Esta última es la herramienta estrella de toda la guía: **probar un permiso "disfrazado" de otra persona**.

> 💬 En tu Ubuntu, `sudo` te pedirá la contraseña la primera vez (`[sudo] contraseña para alumno:`) y la recordará unos minutos. En el libro esa línea no sale porque se ejecutó sin ella; en tu terminal sí.

---

## 0.5 · Monta el laboratorio 🧪

Para entender permisos hay que **ver cómo falla** algo cuando no se tiene permiso. Y para eso hacen falta **otras personas**. Vamos a crear un pequeño elenco:

| Quién | Qué es | Grupos |
|---|---|---|
| 🧑‍🎓 **alumno** | **tú** | `alumno` |
| 👩 **ana** | compañera de equipo | `ana`, **`equipo`** |
| 👨 **beto** | compañero de equipo y de soporte | `beto`, **`equipo`**, **`soporte`** |
| 👩‍🔧 **carla** | solo de soporte | `carla`, **`soporte`** |

(`equipo` y `soporte` son dos grupos de práctica.)

```bash
# 1. Descarga la guía (si no lo has hecho ya)
cd ~
git clone https://github.com/TheBillBull/Guias-y-Herramientas.git

# 2. Monta el laboratorio (te pedirá tu contraseña de sudo y confirmación)
bash ~/Guias-y-Herramientas/guias/permisos-linux-lpic1/laboratorio/preparar-laboratorio.sh

# 3. Entra
cd ~/lab-permisos
ls -l
```

Qué hace el script (y **solo** esto):

1. Crea la carpeta `~/lab-permisos` con tres scripts y unos ficheros de datos.
2. Crea con `sudo` los usuarios **ana, beto, carla** (con la marca `lab-permisos-lpic1` en su comentario) y los grupos **equipo, soporte**.
3. Ajusta tu carpeta personal para que esos usuarios puedan *atravesarla* (esto lo entenderás en el capítulo 3).

| Quiero… | Comando |
|---|---|
| Dejarlo **como nuevo** (por si lo estropeas) | `bash …/preparar-laboratorio.sh` (se puede repetir) |
| Solo la carpeta, sin crear usuarios | `bash …/preparar-laboratorio.sh --sin-usuarios` |
| **Borrarlo todo** al terminar la guía | `bash …/preparar-laboratorio.sh --limpiar` |

> 🛡️ `--limpiar` **solo** borra usuarios que lleven la marca `lab-permisos-lpic1`: nunca toca los tuyos. Y si ya existiera un usuario `ana` que no sea de la guía, el script **se niega** a tocarlo.

Comprobemos que el elenco existe (todas las salidas de este libro se generaron con este mismo laboratorio):

```text
$ id ana
uid=1002(ana) gid=1002(ana) groups=1002(ana),1005(equipo)
$ id beto
uid=1003(beto) gid=1003(beto) groups=1003(beto),1005(equipo),1006(soporte)
$ id carla
uid=1004(carla) gid=1004(carla) groups=1004(carla),1006(soporte)
$ getent group equipo soporte
equipo:x:1005:ana,beto
soporte:x:1006:beto,carla
$ cd ~/lab-permisos
$ ls -l
total 16
-rwxrwxr-x 1 alumno alumno 1015 Oct  9 16:16 cerve.sh
drwxr-xr-x 2 alumno alumno 4096 Oct 16 17:08 datos
-rwxrwxr-x 1 alumno alumno  419 Oct 14 08:43 salario.sh
-rwxr-x--x 1 alumno alumno   93 Oct 13 08:07 saludos.sh
```

Fíjate en que `getent group equipo` lista los **miembros**: `ana,beto`. `alumno` **no** es de `equipo`. Eso nos dará mucho juego.

> 🔁 **Regla de oro:** si una práctica te deja el laboratorio hecho un lío, **vuelve a ejecutar el script** y empieza limpio. Cada capítulo del libro empieza con el laboratorio recién montado.

---

## 0.6 · Probar permisos "como otra persona": `sudo -u`

Esta es la técnica que usaremos **cientos de veces**:

```text
sudo -u ana  COMANDO      →  ejecuta COMANDO siendo ana
```

Por ejemplo, ¿puede **carla** leer el fichero `secreto.txt` que está en tu laboratorio?

```text
$ ls -l datos/secreto.txt
-rw------- 1 alumno alumno 44 Oct 12 09:30 datos/secreto.txt
$ cat datos/secreto.txt
La contraseña del wifi es: patata-frita-42
$ sudo -u carla cat datos/secreto.txt
cat: datos/secreto.txt: Permission denied
```

- Tú (`alumno`) **sí** puedes leerlo: eres su dueño y el fichero tiene permiso `rw-` para el dueño.
- `carla` **no**: `Permission denied`. (¡Aún no sabes leer ese `-rw-------`! Paciencia: es el capítulo 1.)

Cuatro **trucos de prueba** para esta guía:

| Quiero saber… | Comando |
|---|---|
| ¿Puede `ana` **leer** `f`? | `sudo -u ana cat f` |
| ¿Puede `ana` **escribir** en `f`? | `sudo -u ana sh -c 'echo x >> f'` |
| ¿Puede `ana` **ejecutar** `f`? | `sudo -u ana ./f` |
| ¿Quién soy ahora? | `sudo -u ana id` |

> ⚠️ **Ojo con el redirector `>` y `sudo`:** en `sudo echo hola > fichero` el `>` lo hace **tu** shell (sin privilegios) *antes* de que `sudo` entre en juego. Por eso hay que escribir `sudo sh -c 'echo hola > fichero'`. Lo verás en acción en el capítulo 9.

---

## 0.7 · Mensajes de error: inglés y español

Los comandos te hablan en el idioma de tu sistema. **Este libro se generó en inglés** (`LANG=C.UTF-8`); en un Ubuntu en español verás lo mismo, traducido:

| En el libro (inglés) | En tu Ubuntu en español | Significa |
|---|---|---|
| `Permission denied` | `Permiso denegado` | No tienes permiso (el error de esta guía) |
| `Operation not permitted` | `Operación no permitida` | Ni siquiera siendo dueño/pidiéndolo así: acción reservada (p. ej. `chown` a otro) |
| `No such file or directory` | `No existe el archivo o el directorio` | La ruta no existe |
| `Not a directory` | `No es un directorio` | Usaste como carpeta algo que no lo es |
| `cannot access 'x'` | `no se puede acceder a 'x'` | Falló el acceso (a menudo, por permisos) |
| `command not found` | `orden no encontrada` | El comando no existe (o está fuera del `PATH`) |

Y **los meses** de `ls -l` saldrán en minúscula (`oct` en vez de `Oct`), como en tu captura. Es solo cosmética.

---

## 0.8 · Cómo se hacen los ejercicios

Igual que en la guía de *regex y grep*:

| Icono | Nivel |
|---|---|
| 🟢 | Fácil: aplicar lo que acabas de aprender |
| 🟡 | Medio: combinar dos o tres ideas |
| 🔴 | Difícil: hay que pensar un rato |
| ⚫ | Master: preguntas de examen y trampas |

La **solución está escondida** en un desplegable. Técnica: **(1)** lee, **(2)** escribe tu intento, **(3)** ejecútalo en tu laboratorio, **(4)** si no sale, piensa por qué, **(5)** solo entonces mira.

Dos formatos de salida:

- **Bloque + _Resultado_:** un comando (o varios) y debajo lo que salió.
- **Transcripción** (`$ comando` y debajo su salida): cuando hay que ver *qué comando produjo qué*.

---

## 0.9 · 🏋️ Ejercicios

#### 🟢 Ejercicio 0.1 · ¿Quién eres?

Averigua **tu nombre de usuario**, **tu UID** y **tu GID** con un solo comando cada uno (pista: `id` tiene opciones `-u`, `-g`, `-un`, `-gn`).

<details>
<summary>💡 Ver solución</summary>

```text
$ id -u
1001
$ id -g
1001
$ id -un
alumno
$ id -gn
alumno
```

`-u` = UID, `-g` = GID del grupo principal; con `-n` pide el **nombre** en vez del número.
</details>

#### 🟢 Ejercicio 0.2 · Los grupos de beto

¿A qué grupos pertenece `beto`? Hazlo de dos maneras: con `id` y con `groups`.

<details>
<summary>💡 Ver solución</summary>

```text
$ id beto
uid=1003(beto) gid=1003(beto) groups=1003(beto),1005(equipo),1006(soporte)
$ groups beto
beto : beto equipo soporte
$ id -Gn beto
beto equipo soporte
```

Las tres dicen lo mismo. `id -Gn` es la más cómoda para *scripts*: solo los **nombres** de **G**rupos, separados por espacios.
</details>

#### 🟢 Ejercicio 0.3 · ¿Quién está en `equipo`?

Saca los **miembros** del grupo `equipo` y su GID.

<details>
<summary>💡 Ver solución</summary>

```text
$ getent group equipo
equipo:x:1005:ana,beto
```

El GID es el tercer campo (1005 en este laboratorio) y los miembros, el cuarto (`ana,beto`).
</details>

#### 🟡 Ejercicio 0.4 · ¿Es `alumno` de `equipo`?

Comprueba que **tú no** perteneces a `equipo`, pero `ana` sí. Hazlo con `id -Gn` para los dos.

<details>
<summary>💡 Ver solución</summary>

```text
$ id -Gn alumno
alumno
$ id -Gn ana
ana equipo
```

`alumno` solo está en su grupo privado; `ana` está en `ana` y en `equipo`. Esto será decisivo en el capítulo 4.
</details>

#### 🟡 Ejercicio 0.5 · La carpeta personal de ana

¿Cuál es el HOME de `ana` y qué shell usa? (Pista: el campo 6 y 7 de su línea en `/etc/passwd`.)

<details>
<summary>💡 Ver solución</summary>

```text
$ getent passwd ana
ana:x:1002:1002:lab-permisos-lpic1:/home/ana:/bin/bash
$ getent passwd ana | cut -d: -f6,7
/home/ana:/bin/bash
```

`cut -d: -f6,7` corta por `:` y se queda con los campos 6 y 7.
</details>

#### 🟡 Ejercicio 0.6 · Tú, "disfrazado"

Usando `sudo -u`, ejecuta `whoami` como `ana`, como `beto` y como `root`.

<details>
<summary>💡 Ver solución</summary>

```text
$ sudo -u ana whoami
ana
$ sudo -u beto whoami
beto
$ sudo whoami
root
```

Sin `-u`, `sudo` usa `root`.
</details>

#### 🔴 Ejercicio 0.7 · ¿Quién es el UID 0?

El sistema no mira nombres, mira números. Busca **qué usuario(s)** tienen UID 0 en `/etc/passwd` con un solo comando `awk` o `grep`.

<details>
<summary>💡 Ver solución</summary>

```text
$ awk -F: '$3 == 0 {print $1}' /etc/passwd
root
$ grep -E '^[^:]*:[^:]*:0:' /etc/passwd
root:x:0:0:root:/root:/bin/bash
```

Debería salir **solo** `root`. Si en un sistema real ves **otro** usuario con UID 0, ¡alarma! Tiene los mismos poderes que `root` aunque se llame distinto. (Auditoría clásica de LPIC 110.1.)
</details>

#### ⚫ Ejercicio 0.8 · Pregunta de examen

*¿Qué fichero guarda las contraseñas cifradas de los usuarios en un Linux moderno?* a) `/etc/passwd` b) `/etc/shadow` c) `/etc/group` d) `/etc/login.defs`

<details>
<summary>💡 Ver solución</summary>

**b) `/etc/shadow`.** Y se puede comprobar con sus permisos: `-rw-r-----` para `root:shadow`, es decir, no legible por "otros".

```text
$ ls -l /etc/passwd /etc/shadow
-rw-r--r-- 1 root root   3558 Oct 16 17:08 /etc/passwd
-rw-r----- 1 root shadow 1485 Oct 16 17:08 /etc/shadow
```
</details>

---

[📚 Índice](README.md) · [Capítulo 1 · Leer `ls -l` de un vistazo](01-leer-ls-l.md) ➡️
