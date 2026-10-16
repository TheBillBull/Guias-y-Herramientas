# Capítulo 1 · Leer `ls -l` de un vistazo

> 🎯 **Objetivo:** que, en cuanto veas `-rwxrwxr-x 1 alumno alumno 1015 Oct  9 16:16 cerve.sh`, **entiendas cada carácter sin pensar**: qué tipo de cosa es, quién manda, quién puede qué, cuánto pesa y cuándo se tocó.
>
> 📘 **LPIC-1:** 104.5 (permisos y propiedad) · 103.3 (gestión de ficheros).
>
> 🧪 **Antes de empezar:** `cd ~/lab-permisos` (monta el laboratorio con el [Capítulo 0](00-primeros-pasos.md#05--monta-el-laboratorio-) si no lo tienes).

---

## 1.1 · La línea completa, trozo a trozo

Este es el comando que más vas a escribir en esta guía: `ls -l` (*list, long*: "lista en formato largo").

```bash
ls -l cerve.sh
```

_Resultado:_

```text
-rwxrwxr-x 1 alumno alumno 1015 Oct  9 16:16 cerve.sh
```

Una **sola línea**, con **9 datos** separados por espacios. Vamos a ponerles nombre, de izquierda a derecha:

```text
-rwxrwxr-x   1   alumno   alumno   1015   Oct  9 16:16   cerve.sh
└────┬───┘   │     │        │       │          │           └──── ⑨ nombre
     │       │     │        │       │          └──────────────── ⑧ fecha y hora de la última modificación
     │       │     │        │       └─────────────────────────── ⑦ tamaño en bytes
     │       │     │        └─────────────────────────────────── ⑥ grupo propietario
     │       │     └──────────────────────────────────────────── ⑤ usuario propietario (dueño)
     │       └────────────────────────────────────────────────── ④ nº de enlaces
     └────────────────────────────────────────────────────────── ①②③ tipo + PERMISOS (los 10 caracteres)
```

| # | Dato | En `cerve.sh` | Qué significa |
|---|---|---|---|
| ①②③ | **tipo + permisos** | `-rwxrwxr-x` | el corazón de esta guía (ahora mismo lo desmontamos) |
| ④ | enlaces | `1` | cuántos nombres tiene este mismo fichero (casi siempre 1) |
| ⑤ | dueño | `alumno` | el **usuario** propietario |
| ⑥ | grupo | `alumno` | el **grupo** propietario |
| ⑦ | tamaño | `1015` | bytes (≈ 1 KB de texto) |
| ⑧ | fecha | `Oct  9 16:16` | cuándo se **modificó el contenido** por última vez |
| ⑨ | nombre | `cerve.sh` | cómo se llama |

> 💡 `total 16` es la primera línea cuando listas **varios** ficheros o una carpeta: son los bloques de disco que ocupan (en KB). Ignórala al leer permisos.

---

## 1.2 · Los 10 caracteres de los permisos

```text
  -  rwx  rwx  r-x
  │   │    │    │
  │   │    │    └── OTROS  (others):  todos los demás usuarios del sistema
  │   │    └─────── GRUPO  (group):   los miembros del grupo propietario
  │   └──────────── DUEÑO  (user):    el usuario propietario
  └──────────────── TIPO de cosa que es:  - fichero · d carpeta · l enlace …
```

**Primer carácter: el tipo.** Los 9 siguientes son **tres trozos de tres**, y **siempre en el mismo orden**:

| Trozo | Para quién | Letra en las órdenes |
|---|---|---|
| 1º (caracteres 2-4) | el **dueño** (*user*) | `u` |
| 2º (caracteres 5-7) | el **grupo** (*group*) | `g` |
| 3º (caracteres 8-10) | **otros** (*others*) | `o` |
| los tres a la vez | todos (*all*) | `a` |

**Dentro de cada trozo, siempre `r w x` en ese orden**, y una raya `-` significa "este permiso **NO** lo tiene":

| Posición | Letra | Significa (en un fichero) |
|---|---|---|
| 1ª | `r` | **r**ead: leer el contenido |
| 2ª | `w` | **w**rite: modificar el contenido |
| 3ª | `x` | e**x**ecute: ejecutarlo como programa |

> 🧠 **Se lee la POSICIÓN, no la letra.** El trozo `r-x` es "puede leer, **no** puede escribir, puede ejecutar". La raya del medio no es un adorno: es la `w` que falta. Por eso `r-x`, `rw-`, `-wx`… son **todos distintos** y **todos de 3 caracteres**.

### 🔬 Tu línea, leída en voz alta

```text
- rwx rwx r-x     1  alumno  alumno ...  cerve.sh

-    → es un fichero normal
rwx  → el DUEÑO (alumno) puede leer, escribir y ejecutar
rwx  → el GRUPO (alumno) puede leer, escribir y ejecutar
r-x  → LOS DEMÁS pueden leer y ejecutar, pero NO escribir
```

Con eso ya sabes leer **cualquier** línea. El resto es práctica.

### 📋 La receta de 5 segundos

1. **Primer carácter** → ¿qué es? (`-` fichero, `d` carpeta…)
2. **Tres trozos de tres** → dueño | grupo | otros.
3. En cada trozo, ¿`r`? ¿`w`? ¿`x`?
4. **Mira las columnas ⑤ y ⑥** (dueño y grupo): *¿soy yo? ¿es mi grupo?* → de ahí sale **qué trozo me toca** (el capítulo 4 lo explica con todo detalle).
5. Si hay `s`, `S`, `t` o `T` en vez de `x`, hay **permisos especiales** (capítulo 10).

---

## 1.3 · El primer carácter: ¿qué *cosa* es?

En Linux **casi todo es un fichero** (hasta los discos y las impresoras). El primer carácter dice de qué clase:

| Carácter | Tipo | Ejemplo típico |
|:-:|---|---|
| `-` | **fichero normal** (texto, programa, foto…) | `cerve.sh` |
| `d` | **directorio** (carpeta) | `datos` |
| `l` | **enlace simbólico** (un "acceso directo") | `/bin -> usr/bin` |
| `c` | dispositivo de **caracteres** (teclado, `/dev/null`…) | `/dev/null` |
| `b` | dispositivo de **bloques** (discos) | `/dev/sda` |
| `p` | **tubería con nombre** (*pipe*, FIFO) | las crea `mkfifo` |
| `s` | **socket** (comunicación entre programas) | `/run/…/*.sock` |

Los vemos uno a uno, **de verdad**:

```text
$ ls -ld cerve.sh datos
-rwxrwxr-x 1 alumno alumno 1015 Oct  9 16:16 cerve.sh
drwxr-xr-x 2 alumno alumno 4096 Oct 16 17:08 datos
$ ln -s datos/notas.txt enlace.txt
$ ls -l enlace.txt
lrwxrwxrwx 1 alumno alumno 15 Oct 16 17:08 enlace.txt -> datos/notas.txt
$ ls -ld /bin
lrwxrwxrwx 1 root root 7 Apr 22  2024 /bin -> usr/bin
$ ls -l /dev/null
crw-rw-rw- 1 root root 1, 3 Oct 16 09:16 /dev/null
$ mkfifo mi-tuberia
$ ls -l mi-tuberia
prw-rw-r-- 1 alumno alumno 0 Oct 16 17:08 mi-tuberia
$ python3 -c "import socket; s = socket.socket(socket.AF_UNIX); s.bind('mi.sock')"
$ ls -l mi.sock
srwxrwxr-x 1 alumno alumno 0 Oct 16 17:08 mi.sock
```

Cosas que se ven en ese resultado:

- 🔗 **`enlace.txt -> datos/notas.txt`**: un enlace simbólico muestra **a dónde apunta**. Y fíjate: sus permisos son **siempre** `lrwxrwxrwx`. Es normal: *los que cuentan son los del fichero al que apunta*, no los del "acceso directo" (lo veremos en el capítulo 11).
- 📟 **`/dev/null`** no muestra un tamaño sino **`1, 3`**: es el número **mayor y menor** (*major, minor*) del dispositivo. Los ficheros `c` y `b` no tienen "tamaño".
- 💿 Un disco real sería así (el nombre varía según tu equipo: `/dev/sda`, `/dev/nvme0n1`, `/dev/vda`…):

```text
brw-rw---- 1 root disk 8, 0 oct 16 09:16 /dev/sda
```

  `b` de bloques, dueño `root`, grupo **`disk`**: los miembros de `disk` pueden leer y escribir el disco entero. ¡Por eso no te metas en ese grupo a la ligera!

> 🧰 `file cerve.sh` y `stat -c %F cerve.sh` te dicen el tipo con palabras: `Bourne-Again shell script` / `regular file`.

---

## 1.4 · La columna ④: el número de enlaces

Para un **fichero**, es cuántos *nombres* (enlaces duros) tiene. Casi siempre `1`.

Para un **directorio**, el número es **2 + el número de subdirectorios** que contiene (el `2` sale del propio nombre y de su `.`). Comprobémoslo:

```text
$ mkdir carpeta
$ ls -ld carpeta
drwxrwxr-x 2 alumno alumno 4096 Oct 16 17:08 carpeta
$ mkdir carpeta/uno carpeta/dos
$ ls -ld carpeta
drwxrwxr-x 4 alumno alumno 4096 Oct 16 17:08 carpeta
```

Pasó de `2` a `4`: `2 + 2 subcarpetas`. Es un truco para saber cuántas subcarpetas tiene una carpeta sin entrar en ella.

---

## 1.5 · Columnas ⑤ y ⑥: dueño y grupo

Siempre dos nombres: **el usuario propietario** y **el grupo propietario**. Ambos se eligen *por separado*:

```text
$ ls -l datos
total 16
-rw-r--r-- 1 alumno alumno 56 Oct 12 09:30 agenda.txt
-rw-r--r-- 1 alumno alumno 39 Oct 12 09:30 notas.txt
-rw------- 1 alumno alumno 44 Oct 12 09:30 secreto.txt
-rw-r--r-- 1 alumno alumno 37 Oct 12 09:30 ventas.csv
```

Aquí todo es de `alumno alumno`. Más adelante veremos ficheros `root shadow`, `root crontab`, `alumno equipo`…

Recuerda que Linux solo usa **números** y `ls` los traduce a nombres. Con `-n` verás los números reales:

```text
$ ls -l cerve.sh
-rwxrwxr-x 1 alumno alumno 1015 Oct  9 16:16 cerve.sh
$ ls -n cerve.sh
-rwxrwxr-x 1 1001 1001 1015 Oct  9 16:16 cerve.sh
```

Si borras un usuario y sus ficheros siguen ahí, `ls -l` mostrará el **número** (ya no sabe traducirlo): son los llamados ficheros **huérfanos** (`find / -nouser` los busca).

---

## 1.6 · Columna ⑦: el tamaño

En **bytes**. Con `-h` (*human*) lo ves en K, M, G:

```text
$ truncate -s 3M grande.bin
$ ls -l grande.bin
-rw-rw-r-- 1 alumno alumno 3145728 Oct 16 17:08 grande.bin
$ ls -lh grande.bin
-rw-rw-r-- 1 alumno alumno 3.0M Oct 16 17:08 grande.bin
$ ls -lS
total 20
-rw-rw-r-- 1 alumno alumno 3145728 Oct 16 17:08 grande.bin
drwxrwxr-x 4 alumno alumno    4096 Oct 16 17:08 carpeta
drwxr-xr-x 2 alumno alumno    4096 Oct 16 17:08 datos
-rwxrwxr-x 1 alumno alumno    1015 Oct  9 16:16 cerve.sh
-rwxrwxr-x 1 alumno alumno     419 Oct 14 08:43 salario.sh
-rwxr-x--x 1 alumno alumno      93 Oct 13 08:07 saludos.sh
lrwxrwxrwx 1 alumno alumno      15 Oct 16 17:08 enlace.txt -> datos/notas.txt
prw-rw-r-- 1 alumno alumno       0 Oct 16 17:08 mi-tuberia
srwxrwxr-x 1 alumno alumno       0 Oct 16 17:08 mi.sock
```

`ls -lS` ordena por tamaño (el mayor primero). Y ojo con los **directorios**: su "tamaño" (`4096`) es lo que ocupa la **lista de nombres**, no la suma de lo que contienen.

---

## 1.7 · Columna ⑧: la fecha (¿hora o año?)

`ls -l` enseña la fecha de la **última modificación** del contenido (*mtime*). Y tiene una regla curiosa:

| Si el fichero es… | `ls -l` muestra… | Ejemplo |
|---|---|---|
| de hace **menos de 6 meses** | **mes día hora:minuto** | `Oct  9 16:16` |
| de hace **más de 6 meses** (o del futuro) | **mes día año** | `Mar  1  2024` |

```text
$ touch -d '2024-03-01 10:00' viejo.txt
$ ls -l viejo.txt cerve.sh
-rwxrwxr-x 1 alumno alumno 1015 Oct  9 16:16 cerve.sh
-rw-rw-r-- 1 alumno alumno    0 Mar  1  2024 viejo.txt
$ ls --full-time cerve.sh
-rwxrwxr-x 1 alumno alumno 1015 2026-10-09 16:16:00.000000000 +0000 cerve.sh
```

`--full-time` enseña la fecha **exacta** (con segundos y zona horaria). Y hay **tres** fechas por fichero:

| Fecha | Se actualiza cuando… | Opción de `ls` |
|---|---|---|
| **mtime** (*modification*) | cambia el **contenido** | `ls -l` (por defecto) |
| **atime** (*access*) | se **lee** el fichero | `ls -lu` |
| **ctime** (*change*) | cambian los **metadatos** (¡**permisos**, dueño, nombre!) | `ls -lc` |

> 🕵️ El **ctime** es una pista forense: `chmod` y `chown` **no** cambian el `mtime`, pero **sí** el `ctime`. Quien cambia permisos a escondidas no puede falsear el ctime fácilmente.

---

## 1.8 · `ls -d`: ver la ficha de la CARPETA, no su contenido

Cuando le das una **carpeta** a `ls -l`, te lista **lo de dentro**. Pero si lo que quieres son los **permisos de la carpeta misma**, necesitas `-d`:

```text
$ ls -l datos
total 16
-rw-r--r-- 1 alumno alumno 56 Oct 12 09:30 agenda.txt
-rw-r--r-- 1 alumno alumno 39 Oct 12 09:30 notas.txt
-rw------- 1 alumno alumno 44 Oct 12 09:30 secreto.txt
-rw-r--r-- 1 alumno alumno 37 Oct 12 09:30 ventas.csv
$ ls -ld datos
drwxr-xr-x 2 alumno alumno 4096 Oct 16 17:08 datos
$ ls -ld .
drwxr-xr-x 4 alumno alumno 4096 Oct 16 17:08 .
$ ls -ld /tmp
drwxrwxrwt 14 root root 4096 Oct 16 17:08 /tmp
```

En tu captura tienes justo `ls -ld /tmp/`. Regla: **`ls -ld` = "la ficha de ESTA cosa"**. Si te olvidas de la `-d`, preguntas por los vecinos en vez de por la casa.

---

## 1.9 · `stat`: la ficha completa

`ls -l` es un resumen. `stat` te da **todo** de un fichero, incluidos los permisos **en octal y en letras a la vez**:

```text
$ stat cerve.sh
  File: cerve.sh
  Size: 1015      	Blocks: 8          IO Block: 4096   regular file
Device: 254,0	Inode: 599409      Links: 1
Access: (0775/-rwxrwxr-x)  Uid: ( 1001/  alumno)   Gid: ( 1001/  alumno)
Access: 2026-10-09 16:16:00.000000000 +0000
Modify: 2026-10-09 16:16:00.000000000 +0000
Change: 2026-10-16 17:08:01.950034144 +0000
 Birth: 2026-10-16 17:08:01.939853445 +0000
```

Lo que nos interesa es esta línea:

```text
Access: (0775/-rwxrwxr-x)  Uid: ( 1001/  alumno)   Gid: ( 1001/  alumno)
         │    └── en letras      └── dueño: número/nombre      └── grupo: número/nombre
         └─ en OCTAL (el 0 inicial son los bits especiales)
```

Y con `-c` (*custom format*) construyes tu propia ficha. Los códigos más útiles:

| Código | Muestra | Ejemplo |
|:-:|---|---|
| `%a` | permisos en **octal** | `775` |
| `%A` | permisos en **letras** | `-rwxrwxr-x` |
| `%U` | **nombre** del dueño | `alumno` |
| `%G` | **nombre** del grupo | `alumno` |
| `%u` `%g` | **número** de dueño y de grupo | `1001` |
| `%s` | tamaño en bytes | `1015` |
| `%F` | tipo en palabras | `regular file` |
| `%n` | nombre | `cerve.sh` |

```text
$ stat -c '%a  %A  %U:%G  %s  %F  %n' cerve.sh saludos.sh salario.sh datos
775  -rwxrwxr-x  alumno:alumno  1015  regular file  cerve.sh
751  -rwxr-x--x  alumno:alumno  93  regular file  saludos.sh
775  -rwxrwxr-x  alumno:alumno  419  regular file  salario.sh
755  drwxr-xr-x  alumno:alumno  4096  directory  datos
```

> 🌟 **`stat -c '%a %n' *` es la forma más rápida de ver los permisos en octal de todos los ficheros de una carpeta.** Guárdalo.

---

## 1.10 · 🔍 Desmontando TU captura, línea a línea

Ahora ya sabes lo suficiente para leer **la captura que me enseñaste** (la de `~/bin`). Aquí va, **comando a comando**:

### ① `ls -l saludos.sh`

```text
-rwxr-x--x 1 alumno alumno 93 oct 13 08:07 saludos.sh
```

- **Tipo:** `-` → fichero normal
- **Dueño (`alumno`):** `rwx` → leer, escribir, ejecutar
- **Grupo (`alumno`):** `r-x` → leer, ejecutar
- **Otros (el resto del mundo):** `--x` → ejecutar
- **En octal:** `751`

🧐 **Detalle interesante:** los *otros* tienen `--x` (solo ejecutar, sin leer). Para un **script** eso **no sirve de nada**: para lanzarlo, `bash` tiene que **leerlo**. Compruébalo con `carla` (que es "otros" para este fichero):

```text
$ sudo -u carla ./saludos.sh
/bin/bash: /home/alumno/lab-permisos/saludos.sh: Permission denied
$ sudo -u ana ./saludos.sh
/bin/bash: /home/alumno/lab-permisos/saludos.sh: Permission denied
```

(`ana` tampoco puede: es "otros" para este fichero, porque `alumno` no es de `equipo` ni al revés.) Un binario compilado (no un script) sí se podría ejecutar con `--x`; lo comprobaremos en el capítulo 2.

### ② `ls -l salario.sh °` — el error de la captura

```text
alumno@lpic1:~/bin$ ls -l salario.sh °
ls: no se puede acceder a '°': No existe el archivo o el directorio
-rwxrwxr-x 1 alumno alumno 419 oct 14 08:43 salario.sh
```

Se coló un **`°`** (el símbolo de grado) detrás del nombre. Para la terminal, cada palabra separada por un espacio es **otro argumento**, así que `ls` entendió: *"lista `salario.sh` **y también** un fichero llamado `°`"*. Como `°` no existe → error; y luego, aun así, lista `salario.sh`, que sí existe. Lo reproducimos en tu laboratorio:

```text
$ ls -l salario.sh °
ls: cannot access '°': No such file or directory
-rwxrwxr-x 1 alumno alumno 419 Oct 14 08:43 salario.sh
```

> 🎓 Moraleja de LPIC: **un error de `ls` no siempre es un problema de permisos**. `No existe el archivo o el directorio` = la ruta no existe. Un problema de permisos diría `Permiso denegado`. Lee siempre **la frase** del error.

### ③ `ls -l salario.sh`

```text
-rwxrwxr-x 1 alumno alumno 419 oct 14 08:43 salario.sh
```

- **Tipo:** `-` → fichero normal
- **Dueño (`alumno`):** `rwx` → leer, escribir, ejecutar
- **Grupo (`alumno`):** `rwx` → leer, escribir, ejecutar
- **Otros (el resto del mundo):** `r-x` → leer, ejecutar
- **En octal:** `775`

### ④ `ls -l /etc/shadow`

```text
-rw-r----- 1 root shadow 2409 oct 16 11:44 /etc/shadow
```

- **Tipo:** `-` → fichero normal
- **Dueño (`root`):** `rw-` → leer, escribir
- **Grupo (`shadow`):** `r--` → leer
- **Otros (el resto del mundo):** `---` → **nada**
- **En octal:** `640`

👉 **Las contraseñas cifradas**: solo `root` las puede cambiar y solo `root` y los miembros del grupo `shadow` las pueden leer. **Cualquier otro usuario: nada.** (Lo vimos en el [capítulo 0](00-primeros-pasos.md).)

### ⑤ `ls -l /etc/passwd` (con `r--` resaltado en tu captura)

```text
-rw-r--r-- 1 root root 4187 oct 16 11:44 /etc/passwd
```

- **Tipo:** `-` → fichero normal
- **Dueño (`root`):** `rw-` → leer, escribir
- **Grupo (`root`):** `r--` → leer
- **Otros (el resto del mundo):** `r--` → leer
- **En octal:** `644`

El trozo que resaltaste, `r--`, es el de **otros**: *todo el mundo puede leer, nadie más que root puede modificar*. Y lo puedes probar:

```text
$ ls -l /etc/passwd
-rw-r--r-- 1 root root 3558 Oct 16 17:08 /etc/passwd
$ sudo -u carla head -n 1 /etc/passwd
root:x:0:0:root:/root:/bin/bash
$ sudo -u carla sh -c 'echo prueba >> /etc/passwd'
sh: 1: cannot create /etc/passwd: Permission denied
```

`carla` lo lee sin problemas (`root:x:0:0…`), pero **no** puede escribir (`Permission denied`). (Intentar escribir en `/etc/passwd` sin ser `root` es inofensivo: justo para eso están los permisos.)

### ⑥ `ls -ld /tmp/`

```text
drwxrwxrwt 18 root root 4096 oct 16 11:28 /tmp/
```

- **Tipo:** `d` → directorio (carpeta)
- **Dueño (`root`):** `rwx` → listar, crear/borrar/renombrar dentro, entrar
- **Grupo (`root`):** `rwx` → listar, crear/borrar/renombrar dentro, entrar
- **Otros (el resto del mundo):** `rwt` → listar, crear/borrar/renombrar dentro, entrar
- **En octal:** `1777`
- **Bits especiales:** **sticky** (bit pegajoso) (se explican en el capítulo 10)

🧐 **Dos cosas raras:**

- Lleva **`-d`** porque quieres la ficha de la carpeta, no su contenido.
- Termina en **`t`** en vez de `x`: es el **bit *sticky*** (capítulo 10). Hace que, aunque **todos** puedan escribir en `/tmp`, **cada uno solo pueda borrar sus propios ficheros**. Si no, cualquiera borraría los temporales de los demás.

### ⑦ `sudo ls -ld /var/spool/cron/crontabs/`

```text
drwx-wx--T 2 root crontab 4096 oct  7 20:42 /var/spool/cron/crontabs/
```

- **Tipo:** `d` → directorio (carpeta)
- **Dueño (`root`):** `rwx` → listar, crear/borrar/renombrar dentro, entrar
- **Grupo (`crontab`):** `-wx` → crear/borrar/renombrar dentro, entrar
- **Otros (el resto del mundo):** `--T` → **nada**
- **En octal:** `1730`
- **Bits especiales:** **sticky** (bit pegajoso) (se explican en el capítulo 10)

Esta es **la joya** de tu captura. Es la carpeta donde `cron` guarda las **tareas programadas de cada usuario**. Descifremos *por qué* está así de rara:

| Trozo | Valor | Por qué |
|---|---|---|
| dueño `root` | `rwx` | root administra la carpeta |
| grupo `crontab` | `-wx` | el programa `crontab` (que tiene el bit **SGID** `crontab`, mira `ls -l /usr/bin/crontab` → `-rwxr-sr-x root crontab`) puede **entrar y crear/modificar** ficheros, pero **no listar** los de los demás |
| otros | `---` | ningún usuario normal puede ni mirar |
| **`T`** | sticky sin `x` | los ficheros de un usuario **no los puede borrar otro** |

Es un ejemplo perfecto de que **`w` y `x` sin `r`** en una carpeta tiene un uso real: un **buzón** (se pueden *echar* cosas, pero no *ver* qué hay). Lo entenderás del todo en el capítulo 3.

> 💬 Una nota sobre tu `sudo`: para ver **la ficha** de esa carpeta con `ls -ld` normalmente **no hace falta `sudo`** (solo hay que poder *atravesar* `/var/spool/cron`, que suele ser `drwxr-xr-x`). Sí haría falta `sudo` para **listar lo que hay dentro** (`ls /var/spool/cron/crontabs/`), porque ahí te falta el `r`. ¿Por qué? Porque `ls -ld` solo consulta la ficha de la carpeta; no la abre. ¡Capítulo 3!

---

## 1.11 · Otras formas útiles de `ls`

| Comando | Para qué |
|---|---|
| `ls -l` | formato largo |
| `ls -la` | incluye ocultos (`.algo`) |
| `ls -ld carpeta` | la **ficha de la carpeta** misma |
| `ls -lh` | tamaños legibles (K, M, G) |
| `ls -ln` | dueño y grupo como **números** |
| `ls -lt` | ordena por fecha (el más reciente primero) |
| `ls -lS` | ordena por tamaño |
| `ls -lR` | recursivo (entra en subcarpetas) |
| `ls -li` | muestra el **número de inodo** (identifica el fichero de verdad) |
| `ls --full-time` | fecha exacta |
| `stat -c '%a %n' *` | **octal + nombre** |

> 🔎 **¿Y ese `+` o `.` al final de los permisos** (`-rw-r--r--+` o `-rw-r--r--.`)? Un **`+`** avisa de que el fichero tiene **ACL** (permisos extra más allá de `rwx`: capítulo 12). Un **`.`** indica un contexto **SELinux** (Fedora/RHEL; en Ubuntu casi nunca lo verás).

---

## 1.12 · 🏋️ Ejercicios

Para cada ejercicio de "descifrar", **tapa la solución y contesta en voz alta**: tipo, permisos del dueño, del grupo y de otros.

#### 🟢 Ejercicio 1.1 · Un clásico

```text
-rw-r--r-- 1 alumno alumno 220 oct  9 16:16 .bash_logout
```

<details>
<summary>💡 Ver solución</summary>

- **Tipo:** `-` → fichero normal
- **Dueño (`alumno`):** `rw-` → leer, escribir
- **Grupo (`alumno`):** `r--` → leer
- **Otros (el resto del mundo):** `r--` → leer
- **En octal:** `644`

El permiso por defecto de un fichero de texto normal: **el dueño lo edita, los demás lo leen.**
</details>

#### 🟢 Ejercicio 1.2 · Una carpeta

```text
drwxr-xr-x 2 alumno alumno 4096 oct  9 16:16 Documentos
```

<details>
<summary>💡 Ver solución</summary>

- **Tipo:** `d` → directorio (carpeta)
- **Dueño (`alumno`):** `rwx` → listar, crear/borrar/renombrar dentro, entrar
- **Grupo (`alumno`):** `r-x` → listar, entrar
- **Otros (el resto del mundo):** `r-x` → listar, entrar
- **En octal:** `755`

Dueño: todo. Los demás pueden **ver qué hay y entrar**, pero no crear ni borrar dentro. (En el capítulo 3 verás qué significan *listar* y *entrar*.)
</details>

#### 🟢 Ejercicio 1.3 · Solo para mí

```text
-rwx------ 1 alumno alumno 512 oct 10 12:00 backup.sh
```

<details>
<summary>💡 Ver solución</summary>

- **Tipo:** `-` → fichero normal
- **Dueño (`alumno`):** `rwx` → leer, escribir, ejecutar
- **Grupo (`alumno`):** `---` → **nada**
- **Otros (el resto del mundo):** `---` → **nada**
- **En octal:** `700`

El típico script **privado**: nadie más puede ni leerlo.
</details>

#### 🟢 Ejercicio 1.4 · Solo lectura para todos

```text
-r--r--r-- 1 root root 2048 oct 10 12:00 leeme.txt
```

<details>
<summary>💡 Ver solución</summary>

- **Tipo:** `-` → fichero normal
- **Dueño (`root`):** `r--` → leer
- **Grupo (`root`):** `r--` → leer
- **Otros (el resto del mundo):** `r--` → leer
- **En octal:** `444`

**Nadie** puede escribirlo (ni siquiera el dueño, mientras no se haga `chmod u+w`). `root`, en cambio, se lo salta.
</details>

#### 🟡 Ejercicio 1.5 · El fichero que no deja entrar a nadie

```text
---------- 1 alumno alumno 0 oct 10 12:00 cerrado
```

¿Puede su dueño leerlo? ¿Puede cambiarle los permisos?

<details>
<summary>💡 Ver solución</summary>

- **Tipo:** `-` → fichero normal
- **Dueño (`alumno`):** `---` → **nada**
- **Grupo (`alumno`):** `---` → **nada**
- **Otros (el resto del mundo):** `---` → **nada**
- **En octal:** `000`

Su dueño **no puede leerlo** (`---`), pero **sí puede hacerle `chmod`**: cambiar los permisos es cosa del **dueño**, no depende de los permisos del fichero. Comprobémoslo:

```text
$ touch cerrado
$ chmod 000 cerrado
$ cat cerrado
cat: cerrado: Permission denied
$ chmod 600 cerrado
$ cat cerrado
```

(Lo explicamos en el capítulo 6.)
</details>

#### 🟡 Ejercicio 1.6 · Grupo con superpoderes

```text
-rw-rw-r-- 1 alumno equipo 340 oct 10 12:00 informe.odt
```

¿Quiénes pueden **modificarlo** en este laboratorio?

<details>
<summary>💡 Ver solución</summary>

- **Tipo:** `-` → fichero normal
- **Dueño (`alumno`):** `rw-` → leer, escribir
- **Grupo (`equipo`):** `rw-` → leer, escribir
- **Otros (el resto del mundo):** `r--` → leer
- **En octal:** `664`

Pueden escribir: **`alumno`** (dueño) y los miembros del grupo **`equipo`**, es decir, **`ana` y `beto`**. `carla` solo puede leerlo (es "otros").
</details>

#### 🟡 Ejercicio 1.7 · Una carpeta de trabajo

```text
drwxrwx--- 3 root soporte 4096 oct 10 12:00 tickets
```

¿Puede `ana` entrar? ¿Y `carla`? ¿Y `beto`?

<details>
<summary>💡 Ver solución</summary>

- **Tipo:** `d` → directorio (carpeta)
- **Dueño (`root`):** `rwx` → listar, crear/borrar/renombrar dentro, entrar
- **Grupo (`soporte`):** `rwx` → listar, crear/borrar/renombrar dentro, entrar
- **Otros (el resto del mundo):** `---` → **nada**
- **En octal:** `770`

El grupo **`soporte`** tiene acceso total y los demás, nada. En este laboratorio son de `soporte` **`beto` y `carla`** → pueden entrar. **`ana` no** (no es de `soporte`) y entraría como "otros": `---`.
</details>

#### 🟡 Ejercicio 1.8 · Un dispositivo especial (real)

```text
crw-rw-rw- 1 root root 1, 3 oct 16 09:16 /dev/null
```

<details>
<summary>💡 Ver solución</summary>

- **Tipo:** `c` → dispositivo de caracteres
- **Dueño (`root`):** `rw-` → leer, escribir
- **Grupo (`root`):** `rw-` → leer, escribir
- **Otros (el resto del mundo):** `rw-` → leer, escribir
- **En octal:** `666`

Un dispositivo de caracteres que **todo el mundo** puede leer y escribir: el "agujero negro" `/dev/null` donde se tira lo que no se quiere ver (`comando 2>/dev/null`).
</details>

#### 🟡 Ejercicio 1.9 · ¿Qué es esto?

```text
lrwxrwxrwx 1 root root 7 abr 22  2024 /bin -> usr/bin
```

¿Pueden **todos escribir** en `/bin`, entonces?

<details>
<summary>💡 Ver solución</summary>

- **Tipo:** `l` → enlace simbólico
- **Dueño (`root`):** `rwx` → leer, escribir, ejecutar
- **Grupo (`root`):** `rwx` → leer, escribir, ejecutar
- **Otros (el resto del mundo):** `rwx` → leer, escribir, ejecutar
- **En octal:** `777`

**No.** En un enlace simbólico los permisos `rwxrwxrwx` **no cuentan**: Linux los ignora y usa los del **destino** (`/usr/bin`, que es `drwxr-xr-x root root`). Es la trampa clásica: *"¡777 en `/bin`!"* → mentira, es un enlace.
</details>

#### 🔴 Ejercicio 1.10 · De más abierto a más cerrado

Ordena de **más abierto a más cerrado** estos cuatro ficheros: `-rw-------`, `-rw-r--r--`, `-rw-rw-rw-`, `-rw-r-----`.

<details>
<summary>💡 Ver solución</summary>

1. `-rw-rw-rw-` (666): **todo el mundo** puede leer y escribir. 😱 Casi nunca es buena idea.
2. `-rw-r--r--` (644): todos leen, solo el dueño escribe.
3. `-rw-r-----` (640): dueño lee/escribe; el grupo lee; los demás, nada.
4. `-rw-------` (600): solo el dueño.

Truco: cuenta las **letras** (`r`,`w`,`x`) en total; más letras = más abierto (aquí 6, 4, 3 y 2).
</details>

#### 🔴 Ejercicio 1.11 · Buscar con `grep` los scripts del dueño

Lista (con `ls -l` y `grep`) solo los ficheros **normales** de tu laboratorio cuyo **dueño tenga permiso de ejecución**. (Pista: regex sobre el inicio de la línea: `^-` y luego la `x` en la 4ª posición.)

<details>
<summary>💡 Ver solución</summary>

```text
$ ls -l | grep '^-..x'
-rwxrwxr-x 1 alumno alumno    1015 Oct  9 16:16 cerve.sh
-rwxrwxr-x 1 alumno alumno     419 Oct 14 08:43 salario.sh
-rwxr-x--x 1 alumno alumno      93 Oct 13 08:07 saludos.sh
```

`^-` = primer carácter `-` (fichero normal); `..` = `r` y `w` del dueño, cualquier cosa; `x` = ejecución del dueño. (Si quieres más, mira la [guía de regex](../regex-grep-lpic1/README.md).)
</details>

#### 🔴 Ejercicio 1.12 · Cuántas subcarpetas

Sin entrar en `carpeta`, ¿cuántas subcarpetas directas tiene? (Usa el número de enlaces.)

<details>
<summary>💡 Ver solución</summary>

```text
$ ls -ld carpeta
drwxrwxr-x 4 alumno alumno 4096 Oct 16 17:08 carpeta
$ stat -c '%h' carpeta
4
```

`%h` es el número de enlaces: **4 − 2 = 2 subcarpetas**.
</details>

#### 🔴 Ejercicio 1.13 · La fecha del cambio de permisos

Cambia los permisos de `datos/notas.txt` y comprueba que **el `mtime` no cambia pero el `ctime` sí**. (Pista: `stat -c '%y %z'`, o `ls -l` frente a `ls -lc`.)

<details>
<summary>💡 Ver solución</summary>

```text
$ stat -c 'mtime=%y  ctime=%z' datos/notas.txt
mtime=2026-10-12 09:30:00.000000000 +0000  ctime=2026-10-16 17:08:01.963853445 +0000
$ sleep 2
$ chmod 640 datos/notas.txt
$ stat -c 'mtime=%y  ctime=%z' datos/notas.txt
mtime=2026-10-12 09:30:00.000000000 +0000  ctime=2026-10-16 17:08:04.547853385 +0000
```

`%y` es el *mtime* y `%z` el *ctime*. Tras el `chmod`, el **mtime sigue siendo el del 12 de octubre** (el contenido no se tocó) y el **ctime pasa a ser "ahora"**. (`ls -l` enseña el mtime; `ls -lc`, el ctime.)
</details>

#### ⚫ Ejercicio 1.14 · Pregunta de examen

*Dado `-rwxr-sr-x 1 root crontab 39568 ... /usr/bin/crontab`, ¿qué significa la `s` del grupo?* a) El fichero es un enlace simbólico b) Se ejecuta con los permisos del **grupo** propietario c) Solo se puede leer d) Es un directorio

<details>
<summary>💡 Ver solución</summary>

**b)** La `s` en la posición de la `x` del **grupo** es el bit **SGID** con ejecución: el programa corre con los privilegios del **grupo** dueño (aquí, `crontab`), no con los de quien lo lanza. Capítulo 10.
</details>

#### ⚫ Ejercicio 1.15 · Pregunta de examen 2

*¿Cuál de estas líneas corresponde a una **carpeta** en la que el dueño puede todo, el grupo solo entrar y listar, y los demás nada?* a) `-rwxr-x---` b) `drwxr-x---` c) `drwx--x---` d) `d---r-x---`

<details>
<summary>💡 Ver solución</summary>

**b)** `d` (carpeta) + `rwx` (dueño todo) + `r-x` (grupo: listar `r` y entrar `x`) + `---` (otros nada).

a) empieza por `-` (es un fichero). c) el grupo solo tiene `--x` (entrar sin listar). d) el dueño no tiene nada.
</details>

---

⬅️ [Capítulo 0 · Antes de empezar: quién eres, quién es cada uno y el laboratorio](00-primeros-pasos.md) · [📚 Índice](README.md) · [Capítulo 2 · `r`, `w` y `x` en los ficheros: leer, modificar, ejecutar](02-r-w-x-en-ficheros.md) ➡️
