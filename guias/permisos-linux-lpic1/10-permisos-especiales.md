# Capítulo 10 · Permisos especiales: SUID, SGID y *sticky* (`s`, `S`, `t`, `T`, `4755`, `2775`, `1777`)

> 🎯 **Objetivo:** entender los **tres bits especiales**, **verlos** en un `ls -l`, **ponerlos y quitarlos**, saber **por qué existen** (`passwd`, carpetas de equipo, `/tmp`) y **auditar** un sistema buscándolos con `find`.
>
> 📘 **LPIC-1:** 104.5 (SUID, SGID, sticky) · **110.1** (auditar ficheros con SUID/SGID).
>
> 🧪 **Antes de empezar:** `cd ~/lab-permisos`.

---

## 10.1 · Los tres bits especiales de un vistazo

Además de `rwx`, cada fichero guarda **tres interruptores más**. Se escriben como una **cuarta cifra** en octal y **se dibujan sobre la `x`** en `ls -l`:

| Bit | Valor | Dónde se dibuja | Letra | En un **fichero ejecutable** | En una **carpeta** |
|---|:-:|---|:-:|---|---|
| **SUID** (*Set User ID*) | **4** | en la `x` del **dueño** | `s` | se ejecuta **con los privilegios del DUEÑO** del fichero | *(sin efecto en Linux)* |
| **SGID** (*Set Group ID*) | **2** | en la `x` del **grupo** | `s` | se ejecuta **con los privilegios del GRUPO** del fichero | lo que se **cree dentro hereda el grupo** de la carpeta |
| **Sticky** (*bit pegajoso*) | **1** | en la `x` de **otros** | `t` | *(sin efecto en Linux)* | **solo el dueño** de cada fichero (o de la carpeta, o `root`) puede **borrarlo o renombrarlo** |

> 🧠 **Truco de memoria:** el orden **4-2-1** coincide con el orden **dueño-grupo-otros**: el **4** (SUID) va con el **u**suario, el **2** (SGID) con el **g**rupo y el **1** (sticky) con **o**tros. Y están en **la misma columna** que la `x` de cada uno.

```text
        -  r w s   r - s   r - t        ← los 3 bits especiales, dibujados sobre la x
           │ │ │   │ │ │   │ │ └─ sticky (en la x de OTROS)
           │ │ │   │ │ └─── SGID   (en la x del GRUPO)
           │ │ └─────────── SUID   (en la x del DUEÑO)
```

### Mayúscula o minúscula: `s` frente a `S`, `t` frente a `T`

| Se ve | Significa |
|:-:|---|
| **`s`** / **`t`** (minúscula) | el bit especial **y también** la `x` correspondiente |
| **`S`** / **`T`** (mayúscula) | el bit especial **pero SIN `x`** (suele ser un **error** o algo raro) |

```text
$ touch e1 e2 e3 e4
$ chmod 4755 e1
$ chmod 4644 e2
$ chmod 1777 e3
$ chmod 1770 e4
$ stat -c '%a  %A  %n' e1 e2 e3 e4
4755  -rwsr-xr-x  e1
4644  -rwSr--r--  e2
1777  -rwxrwxrwt  e3
1770  -rwxrwx--T  e4
```

- `4755` → `rw**s**r-xr-x`: SUID **con** `x` → minúscula.
- `4644` → `rw**S**r--r--`: SUID **sin** `x` → **mayúscula** (¡un SUID que no se puede ejecutar! no sirve para nada).
- `1777` → `rwxrwxrw**t**`: sticky con `x` de otros.
- `1770` → `rwxrwx--**T**`: sticky **sin** `x` de otros (como tu `crontabs`: `drwx-wx--T`).

---

## 10.2 · SUID: ejecutar "como el dueño" 🪄

### ¿Para qué sirve? El caso de `passwd`

Tu contraseña vive en `/etc/shadow`, que **solo `root` puede modificar** (`-rw-r-----`). Pero tú puedes cambiar **tu** contraseña con `passwd` sin ser `root`. ¿Cómo? Porque `passwd` es un programa **SUID `root`**: cuando lo ejecutas, **durante esa ejecución actúa como `root`**.

```text
$ ls -l /usr/bin/passwd /usr/bin/sudo /usr/bin/su /usr/bin/mount /usr/bin/chsh /usr/bin/newgrp
-rwsr-xr-x 1 root root  44760 May 30  2024 /usr/bin/chsh
-rwsr-xr-x 1 root root  51584 Aug 19 16:47 /usr/bin/mount
-rwsr-xr-x 1 root root  40664 May 30  2024 /usr/bin/newgrp
-rwsr-xr-x 1 root root  64152 May 30  2024 /usr/bin/passwd
-rwsr-xr-x 1 root root  55680 Aug 19 16:47 /usr/bin/su
-rwsr-xr-x 1 root root 282032 Sep 21 18:37 /usr/bin/sudo
$ ls -l /etc/shadow
-rw-r----- 1 root shadow 1485 Oct 16 17:08 /etc/shadow
```

Todos son `-rwsr-xr-x` y de `root`: la **`s`** en lugar de la `x` del dueño.

### Real UID y *effective* UID

Un proceso tiene **dos identidades**:

| | Qué es | Sirve para |
|---|---|---|
| **UID real** (*ruid*) | **quién lo lanzó** | saber quién es "de verdad" |
| **UID efectivo** (*euid*) | **con qué identidad actúa** | **comprobar los permisos** |

Normalmente son iguales. Con **SUID**, el euid pasa a ser el **dueño del fichero**. Lo vemos **con tus propios ojos** usando una copia del programa `id`:

```text
$ cp /usr/bin/id id-suid
$ cp /usr/bin/whoami whoami-suid
$ sudo chown root id-suid whoami-suid
$ sudo chmod u+s id-suid whoami-suid
$ ls -l id-suid whoami-suid
-rwsr-xr-x 1 root alumno 39432 Oct 16 17:08 id-suid
-rwsr-xr-x 1 root alumno 35336 Oct 16 17:08 whoami-suid
$ id
uid=1001(alumno) gid=1001(alumno) groups=1001(alumno)
$ ./id-suid
uid=1001(alumno) gid=1001(alumno) euid=0(root) groups=1001(alumno)
$ whoami
alumno
$ ./whoami-suid
root
```

- `id` normal: `uid=1001(alumno)`.
- `./id-suid`: `uid=1001(alumno)` **y** `euid=0(root)`: **tú sigues siendo `alumno`** (real), pero **el proceso actúa como `root`** (efectivo).
- `./whoami-suid` imprime **`root`** (muestra el usuario *efectivo*).

Sin SUID, el mismo programa copiado se ejecuta como tú:

```text
$ cp /usr/bin/id id-normal
$ ./id-normal
uid=1001(alumno) gid=1001(alumno) groups=1001(alumno)
```

### ⚠️ Linux **ignora el SUID en los scripts**

Un script SUID sería muy peligroso (el intérprete lee un fichero que alguien podría cambiar en medio…), así que **el kernel de Linux ignora el bit SUID en los ficheros interpretados** (los que empiezan por `#!`). Solo vale en **binarios compilados**:

```text
$ printf '#!/bin/bash\nid\n' > suid-script.sh
$ sudo chown root suid-script.sh
$ sudo chmod 4755 suid-script.sh
$ ls -l suid-script.sh
-rwsr-xr-x 1 root alumno 15 Oct 16 17:08 suid-script.sh
$ ./suid-script.sh
uid=1001(alumno) gid=1001(alumno) groups=1001(alumno)
```

Pese a ser `-rwsr-xr-x` y de `root`, el script **no** gana privilegios (no hay `euid=0`). Si necesitas privilegios en un script, usa `sudo` con una regla en `/etc/sudoers`, no SUID.

### 🚨 El SUID es poderoso, así que es un **objetivo**

Un programa SUID `root` con un fallo es una **puerta a convertirse en `root`**. Por eso:

- El sistema tiene **pocos** SUID, todos **auditados**.
- **Nunca** pongas SUID a un editor, un intérprete (`bash`, `python`), `find`, `cp`… equivaldría a regalar `root`.
- **Audita** tu sistema periódicamente (apartado 10.7).

```text
$ find /usr -perm -4000 -type f 2>/dev/null | sort
/usr/bin/chfn
/usr/bin/chsh
/usr/bin/gpasswd
/usr/bin/mount
/usr/bin/newgrp
/usr/bin/passwd
/usr/bin/su
/usr/bin/sudo
/usr/bin/umount
/usr/lib/dbus-1.0/dbus-daemon-launch-helper
/usr/lib/polkit-1/polkit-agent-helper-1
```

(El resultado varía de un sistema a otro; en el tuyo habrá más. Compáralo con una lista "buena" conocida y **desconfía de cualquier recién llegado**.)

---

## 10.3 · SGID en **ficheros**: ejecutar "con el grupo del fichero"

Igual que el SUID, pero con el **grupo**: el proceso actúa con el **GID efectivo** = grupo del fichero.

```text
$ cp /usr/bin/id id-sgid
$ sudo chgrp equipo id-sgid
$ sudo chmod g+s id-sgid
$ ls -l id-sgid
-rwxr-sr-x 1 alumno equipo 39432 Oct 16 17:08 id-sgid
$ ./id-sgid
uid=1001(alumno) gid=1001(alumno) egid=1005(equipo) groups=1005(equipo),1001(alumno)
```

Aparece `egid=1005(equipo)` (el **grupo efectivo**) mientras que tu `gid` real sigue siendo `alumno`. Un ejemplo real es `/usr/bin/crontab`, que es `-rwxr-sr-x root crontab`: gracias al SGID, `crontab` **escribe en la carpeta de `cron`** (que solo permite el grupo `crontab`, ¡tu captura!) sin que tú pertenezcas a ese grupo.

```text
$ ls -l /usr/bin/expiry
-rwxr-sr-x 1 root shadow 27152 May 30  2024 /usr/bin/expiry
```

---

## 10.4 · SGID en **carpetas**: el truco de los equipos 👥

Esta es **la** utilidad práctica del SGID. En una carpeta con SGID:

> 📌 **Todo fichero o carpeta creado dentro hereda el GRUPO de la carpeta** (en vez del grupo principal de quien lo crea). Y las **subcarpetas** heredan además el propio bit SGID.

### Sin SGID (el problema)

```text
$ mkdir sin-sgid
$ sudo chgrp equipo sin-sgid
$ chmod 770 sin-sgid
$ sudo -u ana sh -c 'umask 002; touch sin-sgid/de-ana.txt'
$ sudo -u beto sh -c 'umask 002; touch sin-sgid/de-beto.txt'
$ ls -l sin-sgid
total 0
-rw-rw-r-- 1 ana  ana  0 Oct 16 17:08 de-ana.txt
-rw-rw-r-- 1 beto beto 0 Oct 16 17:08 de-beto.txt
```

Cada uno creó su fichero con **su** grupo principal (`ana:ana`, `beto:beto`): los demás miembros de `equipo` **no podrán editarlos**. (El `umask 002` nos da `rw-rw-r--` como en una sesión normal de Ubuntu.)

### ⚠️ Antes de nada: el SGID que **desaparece en silencio**

Un detalle que desconcierta a todo el mundo. Tú (`alumno`) **no eres miembro** de `equipo`. Mira qué pasa si intentas poner el SGID **sin `sudo`**:

```text
$ mkdir prueba-sgid
$ sudo chgrp equipo prueba-sgid
$ chmod 2770 prueba-sgid
$ ls -ld prueba-sgid
drwxrwx--- 2 alumno equipo 4096 Oct 16 17:08 prueba-sgid
$ sudo chmod 2770 prueba-sgid
$ ls -ld prueba-sgid
drwxrws--- 2 alumno equipo 4096 Oct 16 17:08 prueba-sgid
```

El primer `chmod 2770` **no da error, pero no pone la `s`** (`drwxrwx---`). Con `sudo` sí (`drwxrws---`). Es una protección del kernel: *si no perteneces al grupo de un fichero o carpeta, tu `chmod` no puede activar el SGID* (si no, cualquiera podría "colarse" con los privilegios de un grupo ajeno). **Si no ves la `s` tras el `chmod`, esta es la causa.** En la vida real lo normal es que quien prepara la carpeta sea `root` (con `sudo`) o miembro del grupo.

### Con SGID (la solución)

```text
$ mkdir con-sgid
$ sudo chgrp equipo con-sgid
$ sudo chmod 2770 con-sgid
$ ls -ld con-sgid
drwxrws--- 2 alumno equipo 4096 Oct 16 17:08 con-sgid
$ sudo -u ana sh -c 'umask 002; touch con-sgid/de-ana.txt; mkdir con-sgid/sub'
$ sudo -u beto sh -c 'umask 002; touch con-sgid/de-beto.txt'
$ ls -l con-sgid
total 4
-rw-rw-r-- 1 ana  equipo    0 Oct 16 17:08 de-ana.txt
-rw-rw-r-- 1 beto equipo    0 Oct 16 17:08 de-beto.txt
drwxrwsr-x 2 ana  equipo 4096 Oct 16 17:08 sub
```

¡Ahora **todo es del grupo `equipo`**, y la subcarpeta `sub` heredó incluso la `s` (`drwxrwsr-x`). Comprueba que **cada uno puede editar lo del otro**:

```text
$ sudo -u beto sh -c 'echo "editado por beto" >> con-sgid/de-ana.txt'
$ cat con-sgid/de-ana.txt
editado por beto
$ sudo -u carla ls con-sgid
ls: cannot open directory 'con-sgid': Permission denied
```

`beto` edita el fichero de `ana` (comparten grupo y el fichero es `rw-rw----`); `carla` (de otro grupo) ni entra.

> ⭐ **Receta de carpeta de equipo:** `sudo chgrp equipo carpeta` + **`sudo chmod 2770 carpeta`** (o `2775` si otros deben leer) + **`umask 002`** para los miembros. Para que **lo nuevo** sea editable por el grupo necesitas **las dos cosas**: SGID (el grupo correcto) y `umask 002` (el permiso `w` de grupo).

### 🔎 Trampa: `mv` frente a `cp`

El grupo se hereda al **crear**. Pero `mv` no crea nada, **mueve**, y el fichero **conserva su grupo**:

```text
$ echo "creado fuera" > fuera.txt
$ echo "copiado" > origen2.txt
$ cp origen2.txt con-sgid/copiado.txt
$ mv fuera.txt con-sgid/movido.txt
$ ls -l con-sgid/copiado.txt con-sgid/movido.txt
-rw-rw-r-- 1 alumno equipo  8 Oct 16 17:08 con-sgid/copiado.txt
-rw-rw-r-- 1 alumno alumno 13 Oct 16 17:08 con-sgid/movido.txt
```

El copiado (`cp`) es del grupo **`equipo`** (heredado); el movido (`mv`) conserva **`alumno`**. Si pasa en tu equipo, arréglalo con `chgrp`.

---

## 10.5 · *Sticky*: "pegajoso" 🍯 (carpetas públicas seguras)

### El problema

Una carpeta con `rwxrwxrwx` (`777`) deja que **cualquiera** cree… y que **cualquiera borre lo de los demás** (borrar depende de la carpeta, ¡capítulo 3!). En `/tmp` eso sería un desastre.

```text
$ mkdir abierta-sin
$ chmod 777 abierta-sin
$ sudo -u ana touch abierta-sin/ana.txt
$ sudo -u beto rm -f abierta-sin/ana.txt
$ ls abierta-sin
```

`beto` borró el fichero de `ana`. 😱

### La solución: el bit *sticky*

Con el bit **sticky** (`1777`), en esa carpeta solo pueden **borrar o renombrar** un fichero:

1. su **dueño**,
2. el **dueño de la carpeta**,
3. `root`.

```text
$ mkdir abierta-con
$ chmod 1777 abierta-con
$ ls -ld abierta-con
drwxrwxrwt 2 alumno alumno 4096 Oct 16 17:08 abierta-con
$ sudo -u ana touch abierta-con/ana.txt
$ sudo -u beto rm -f abierta-con/ana.txt
rm: cannot remove 'abierta-con/ana.txt': Operation not permitted
$ sudo -u beto mv abierta-con/ana.txt abierta-con/beto.txt
mv: cannot move 'abierta-con/ana.txt' to 'abierta-con/beto.txt': Operation not permitted
$ ls abierta-con
ana.txt
$ sudo -u ana rm -f abierta-con/ana.txt
$ ls abierta-con
```

- `beto` **no puede** borrar ni renombrar el fichero de `ana` (`Operation not permitted`).
- `ana` **sí puede** borrar el suyo.
- Y recuerda: el **dueño de la carpeta** (tú, `alumno`) y `root` también podrían.

Por eso **`/tmp`**, **`/var/tmp`** y **`/dev/shm`** son `1777`:

```text
$ ls -ld /tmp /var/tmp /dev/shm
drwxrwxrwt  3 root root   60 Oct 16 15:58 /dev/shm
drwxrwxrwt 14 root root 4096 Oct 16 17:08 /tmp
drwxrwxrwt  3 root root 4096 Oct 16 17:06 /var/tmp
```

### El buzón de tu captura, **recreado**: `1730`

`drwx-wx--T` es el `crontabs`: grupo con `-wx` (deposita y entra, sin listar) + sticky (nadie borra lo del otro). Lo reproducimos con el grupo `equipo`:

```text
$ mkdir buzon-seguro
$ sudo chgrp equipo buzon-seguro
$ chmod 1730 buzon-seguro
$ ls -ld buzon-seguro
drwx-wx--T 2 alumno equipo 4096 Oct 16 17:08 buzon-seguro
$ sudo -u ana touch buzon-seguro/de-ana
$ sudo -u beto touch buzon-seguro/de-beto
$ sudo -u beto rm -f buzon-seguro/de-ana
rm: cannot remove 'buzon-seguro/de-ana': Operation not permitted
$ sudo -u ana ls buzon-seguro
ls: cannot open directory 'buzon-seguro': Permission denied
$ ls buzon-seguro
de-ana	de-beto
```

Cada miembro **deposita**; ninguno **lista** ni **borra lo del otro**. Eso es exactamente `/var/spool/cron/crontabs`.

---

## 10.6 · Poner y quitar los bits especiales

| Quiero… | Simbólico | Octal (4 cifras) |
|---|---|---|
| **SUID** | `chmod u+s f` | `chmod 4755 f` |
| **SGID** | `chmod g+s f` | `chmod 2755 f` / `2775 carpeta` |
| **Sticky** | `chmod +t carpeta` (o `o+t`) | `chmod 1777 carpeta` |
| Varios a la vez | `chmod u+s,g+s f` | `chmod 6755 f` (4+2) |
| Quitar SUID | `chmod u-s f` | `chmod 0755 f` (en ficheros) |
| Quitar SGID | `chmod g-s f` | `chmod 0755 f` (en ficheros); en **carpetas**: `g-s` o `00755` |
| Quitar sticky | `chmod -t carpeta` | `chmod 0777 carpeta` |

Cosas a recordar (ya las vimos antes):

- **`chown`/`chgrp` borra el SUID/SGID** de un fichero (capítulo 9): primero `chown`, luego `chmod`.
- **Si no perteneces al grupo** del fichero o carpeta, tu `chmod` **no puede poner el SGID** (se descarta sin avisar): usa `sudo` (apartado 10.4).
- `chmod 755 f` **quita** los bits especiales de un **fichero**, pero `chmod 755 carpeta` **no** quita el SGID de una **carpeta** (capítulo 7).
- **Modificar el contenido** de un fichero SUID/SGID siendo un usuario sin privilegios **también borra** el SUID/SGID (otra protección del kernel). Lo comprobamos:

```text
$ cp /usr/bin/id id-modificado
$ sudo chown ana id-modificado
$ sudo chmod 4777 id-modificado
$ ls -l id-modificado
-rwsrwxrwx 1 ana alumno 39432 Oct 16 17:08 id-modificado
$ sudo -u carla sh -c 'echo "x" >> id-modificado'
$ ls -l id-modificado
-rwxrwxrwx 1 ana alumno 39434 Oct 16 17:08 id-modificado
```

(`carla` consigue **escribir**, pero al hacerlo el kernel quita el SUID: `rwsrwxrwx` → `rwxrwxrwx`.)

---

## 10.7 · 🔎 Auditar: encontrar SUID, SGID y sticky con `find -perm`

El examen LPIC-1 (objetivo **110.1**) pide saber **buscar ficheros con SUID/SGID**. La herramienta es **`find -perm`**, que tiene **tres formas**, ¡y es de las cosas que más se confunden!:

| Forma | Significa | Ejemplo | Se lee |
|---|---|---|---|
| `-perm 644` | permisos **exactamente** `644` | `find . -perm 644` | ni más ni menos |
| `-perm -644` (con **`-`**) | **TODOS** esos bits puestos (y quizá más) | `find . -perm -644` | "al menos `rw-r--r--`" |
| `-perm /644` (con **`/`**) | **ALGUNO** de esos bits puesto | `find . -perm /111` | "alguien tiene `x`" |

Lo vemos en directo con unos ficheros de prueba:

```text
$ mkdir auditoria
$ cd auditoria
$ touch a b c d e
$ chmod 644 a
$ chmod 664 b
$ chmod 755 c
$ chmod 4755 d
$ chmod 2755 e
$ for f in a b c d e; do stat -c '%a  %A  %n' $f; done
644  -rw-r--r--  a
664  -rw-rw-r--  b
755  -rwxr-xr-x  c
4755  -rwsr-xr-x  d
2755  -rwxr-sr-x  e
$ cd ..
```

Ahora las búsquedas (cada una con su pregunta):

```text
$ cd auditoria
$ echo "--- exactamente 644:";                find . -type f -perm 644 | sort
--- exactamente 644:
./a
$ echo "--- al menos rw-r--r-- (-644):";       find . -type f -perm -644 | sort
--- al menos rw-r--r-- (-644):
./a
./b
./c
./d
./e
$ echo "--- alguien con x (/111):";            find . -type f -perm /111 | sort
--- alguien con x (/111):
./c
./d
./e
$ echo "--- SUID (-4000):";                    find . -type f -perm -4000 | sort
--- SUID (-4000):
./d
$ echo "--- SGID (-2000):";                    find . -type f -perm -2000 | sort
--- SGID (-2000):
./e
$ echo "--- SUID o SGID (/6000):";             find . -type f -perm /6000 | sort
--- SUID o SGID (/6000):
./d
./e
$ cd ..
```

Las tres recetas de auditoría que debes **saber de memoria**:

| Quiero encontrar… | Comando |
|---|---|
| Ficheros con **SUID** | `find / -perm -4000 -type f 2>/dev/null` |
| Ficheros con **SGID** | `find / -perm -2000 -type f 2>/dev/null` |
| **SUID o SGID** | `find / -perm /6000 -type f 2>/dev/null` (o `\( -perm -4000 -o -perm -2000 \)`) |
| Carpetas **escribibles por todos y SIN sticky** (peligrosas) | `find / -xdev -type d -perm -0002 ! -perm -1000 2>/dev/null` |
| Ficheros **escribibles por cualquiera** | `find / -xdev -type f -perm -0002 2>/dev/null` |
| Ficheros **sin dueño** | `find / -nouser -o -nogroup 2>/dev/null` |

> 💡 El `2>/dev/null` tira a la basura los *"Permission denied"* de las carpetas donde no puedes entrar (con `sudo` no hacen falta). Y **`-xdev`** impide que `find` salte a otros sistemas de ficheros (`/proc`, `/sys`…).

```text
$ find /tmp /var/tmp -xdev -type d -perm -0002 ! -perm -1000 2>/dev/null
/tmp/exp
$ echo "(si no sale nada, ninguna carpeta pública sin sticky)"
(si no sale nada, ninguna carpeta pública sin sticky)
```

---

## 10.8 · 📋 Resumen para el examen

```text
SUID  4   rws r-x r-x   4755   ejecuta con los privilegios del DUEÑO     (passwd)
SGID  2   rwx r-s r-x   2755   ejecuta con los privilegios del GRUPO     (crontab)
SGID  2   rwx rws r-x   2775   carpeta: lo nuevo hereda el GRUPO         (equipo)
STICKY 1  rwx rwx rwt   1777   carpeta: cada uno borra solo lo suyo      (/tmp)
```

| Pregunta típica | Respuesta |
|---|---|
| ¿Qué hace el SUID? | El programa se ejecuta con los permisos de **su dueño**, no de quien lo lanza |
| ¿Cómo se ve? | `s` en lugar de la `x` del dueño (`rws`) |
| ¿Qué significa `S` mayúscula? | Bit especial **sin** `x` debajo |
| ¿Para qué sirve el SGID en una carpeta? | Que lo nuevo **herede el grupo** de la carpeta |
| ¿Para qué sirve el *sticky*? | Que solo el dueño (o el de la carpeta / root) **borre** sus ficheros |
| ¿Dónde se usa el *sticky*? | `/tmp`, `/var/tmp` |
| ¿Cómo busco los SUID? | `find / -perm -4000` |
| ¿Funciona el SUID en scripts? | **No** (Linux lo ignora) |

---

## 10.9 · 🏋️ Ejercicios

#### 🟢 Ejercicio 10.1 · Leer un `s`

```text
-rwsr-xr-x 1 root root 64152 may 30  2024 /usr/bin/passwd
```

¿Qué hace la `s`? ¿Cuál es su octal?

<details>
<summary>💡 Ver solución</summary>

- **Tipo:** `-` → fichero normal
- **Dueño (`root`):** `rws` → leer, escribir, ejecutar
- **Grupo (`root`):** `r-x` → leer, ejecutar
- **Otros (el resto del mundo):** `r-x` → leer, ejecutar
- **En octal:** `4755`
- **Bits especiales:** **SUID** (bit especial de usuario) (se explican en el capítulo 10)

Cuando **cualquier** usuario lo ejecuta, el programa corre **como `root`** (su dueño): por eso puede escribir en `/etc/shadow`.
</details>

#### 🟢 Ejercicio 10.2 · Leer un `t`

```text
drwxrwxrwt 18 root root 4096 oct 16 11:28 /tmp
```

<details>
<summary>💡 Ver solución</summary>

- **Tipo:** `d` → directorio (carpeta)
- **Dueño (`root`):** `rwx` → listar, crear/borrar/renombrar dentro, entrar
- **Grupo (`root`):** `rwx` → listar, crear/borrar/renombrar dentro, entrar
- **Otros (el resto del mundo):** `rwt` → listar, crear/borrar/renombrar dentro, entrar
- **En octal:** `1777`
- **Bits especiales:** **sticky** (bit pegajoso) (se explican en el capítulo 10)

La `t` es el **sticky**: todos pueden crear en `/tmp`, pero cada uno solo borra lo suyo.
</details>

#### 🟢 Ejercicio 10.3 · Leer un `T`

```text
drwx-wx--T 2 root crontab 4096 oct  7 20:42 /var/spool/cron/crontabs
```

<details>
<summary>💡 Ver solución</summary>

- **Tipo:** `d` → directorio (carpeta)
- **Dueño (`root`):** `rwx` → listar, crear/borrar/renombrar dentro, entrar
- **Grupo (`crontab`):** `-wx` → crear/borrar/renombrar dentro, entrar
- **Otros (el resto del mundo):** `--T` → **nada**
- **En octal:** `1730`
- **Bits especiales:** **sticky** (bit pegajoso) (se explican en el capítulo 10)

La `T` mayúscula indica **sticky sin `x` para otros** (otros no tienen ningún permiso: `---`, y encima el sticky).
</details>

#### 🟡 Ejercicio 10.4 · Poner el SGID a una carpeta de equipo

Crea `mi-equipo`, del grupo `equipo`, de forma que lo que `ana` cree dentro herede el grupo `equipo`. (Recuerda que tú no eres de `equipo`.)

<details>
<summary>💡 Ver solución</summary>

```text
$ mkdir mi-equipo
$ sudo chgrp equipo mi-equipo
$ sudo chmod 2775 mi-equipo
$ ls -ld mi-equipo
drwxrwsr-x 2 alumno equipo 4096 Oct 16 17:08 mi-equipo
$ sudo -u ana touch mi-equipo/nota-de-ana.txt
$ ls -l mi-equipo
total 0
-rw-r--r-- 1 ana equipo 0 Oct 16 17:08 nota-de-ana.txt
```
</details>

#### 🟡 Ejercicio 10.5 · Un SUID de juguete

Crea `quien-soy` (copia de `whoami`), propiedad de `root`, que al ejecutarlo **tú** diga `root`.

<details>
<summary>💡 Ver solución</summary>

```text
$ cp /usr/bin/whoami quien-soy
$ sudo chown root quien-soy
$ sudo chmod u+s quien-soy
$ ./quien-soy
root
```

Recuerda el orden: `chown` **primero**, `chmod u+s` **después**.
</details>

#### 🟡 Ejercicio 10.6 · Sticky en tu carpeta compartida

Haz `compartida` de modo que **cualquiera pueda crear** pero **solo cada uno borre lo suyo**.

<details>
<summary>💡 Ver solución</summary>

```text
$ mkdir compartida
$ chmod 1777 compartida
$ ls -ld compartida
drwxrwxrwt 2 alumno alumno 4096 Oct 16 17:08 compartida
$ sudo -u ana touch compartida/a.txt
$ sudo -u carla rm -f compartida/a.txt
rm: cannot remove 'compartida/a.txt': Operation not permitted
$ ls compartida
a.txt
```
</details>

#### 🟡 Ejercicio 10.7 · Octal con `s` y `t`

Pasa a octal: `rwsr-xr-x` · `rwxr-sr-x` · `rwxrwxrwt` · `rwx--S---`. Compruébalo con `permisos`.

<details>
<summary>💡 Ver solución</summary>

```text
$ permisos rwsr-xr-x | grep Octal
  Octal     4755
$ permisos rwxr-sr-x | grep Octal
  Octal     2755
$ permisos rwxrwxrwt | grep Octal
  Octal     1777
$ permisos rwx--S--- | grep Octal
  Octal     2700
```

`4755`, `2755`, `1777`, `2700` (la `S` mayúscula del grupo = SGID sin `x`).
</details>

#### 🔴 Ejercicio 10.8 · ¿Por qué no funciona el SUID en mi script?

Un compañero ha hecho `chmod 4755 backup.sh` (script de `root`) y dice que "no tiene privilegios". ¿Por qué? ¿Qué le recomendarías?

<details>
<summary>💡 Ver solución</summary>

Porque **Linux ignora el SUID/SGID en los scripts** (ficheros `#!`). Opciones: (1) usar `sudo` con una regla concreta en `sudoers`; (2) un pequeño programa compilado SUID que lance el script (¡con cuidado!); (3) usar una unidad `systemd`/`cron` que corra como `root`.
</details>

#### 🔴 Ejercicio 10.9 · Carpetas públicas peligrosas

¿Qué comando busca carpetas **escribibles por todos y sin sticky**? Pruébalo creando una a propósito.

<details>
<summary>💡 Ver solución</summary>

```text
$ mkdir -p peligro-publica
$ chmod 777 peligro-publica
$ find . -type d -perm -0002 ! -perm -1000
./abierta-sin
./peligro-publica
```

`-perm -0002` = "`w` para otros"; `! -perm -1000` = "**sin** sticky". (Esta salida también incluye `abierta-sin`, que dejamos así antes.) Soluciones: `chmod +t carpeta`.
</details>

#### 🔴 Ejercicio 10.10 · Heredar el grupo… pero no los permisos

`ana` crea `todo.txt` en una carpeta `2775` del grupo `equipo` con `umask 022`. ¿Qué permisos tiene `todo.txt` y puede `beto` editarlo?

<details>
<summary>💡 Ver solución</summary>

```text
$ mkdir equipo2
$ sudo chgrp equipo equipo2
$ sudo chmod 2775 equipo2
$ sudo -u ana sh -c 'umask 022; touch equipo2/todo.txt'
$ ls -l equipo2/todo.txt
-rw-r--r-- 1 ana equipo 0 Oct 16 17:08 equipo2/todo.txt
$ sudo -u beto sh -c 'echo x >> equipo2/todo.txt'
sh: 1: cannot create equipo2/todo.txt: Permission denied
```

Hereda el **grupo** (`equipo`), pero con `umask 022` los permisos son `rw-r--r--`: `beto` **no** puede editarlo. Para el trabajo en equipo hacen falta **las dos cosas**: SGID + `umask 002`.
</details>

#### 🔴 Ejercicio 10.11 · Quitar bits especiales

Tienes `f` con `6755`. Quita **solo el SGID** sin tocar el SUID, con símbolos.

<details>
<summary>💡 Ver solución</summary>

```text
$ touch f6755
$ chmod 6755 f6755
$ stat -c '%a %A' f6755
6755 -rwsr-sr-x
$ chmod g-s f6755
$ stat -c '%a %A' f6755
4755 -rwsr-xr-x
```
</details>

#### ⚫ Ejercicio 10.12 · Auditoría

Encuentra todos los ficheros con **SUID o SGID** dentro de `/usr/bin`, ordenados, con una sola orden.

<details>
<summary>💡 Ver solución</summary>

```text
$ find /usr/bin -type f -perm /6000 2>/dev/null | sort
/usr/bin/chage
/usr/bin/chfn
/usr/bin/chsh
/usr/bin/expiry
/usr/bin/gpasswd
/usr/bin/mount
/usr/bin/newgrp
/usr/bin/passwd
/usr/bin/su
/usr/bin/sudo
/usr/bin/umount
```

(`-perm /6000` = "SUID **o** SGID". Otra forma: `\( -perm -4000 -o -perm -2000 \)`.)
</details>

#### ⚫ Ejercicio 10.13 · `-perm 644`, `-perm -644` y `-perm /644`

Con los ficheros de `auditoria/` (`644`, `664`, `755`, `4755`, `2755`), ¿cuáles encuentra cada una?

<details>
<summary>💡 Ver solución</summary>

```text
$ cd auditoria
$ echo "exacto 644:";   find . -type f -perm 644  | sort
exacto 644:
./a
$ echo "-644 (todos):";  find . -type f -perm -644 | sort
-644 (todos):
./a
./b
./c
./d
./e
$ echo "/644 (alguno):"; find . -type f -perm /644 | sort
/644 (alguno):
./a
./b
./c
./d
./e
$ cd ..
```

- `-perm 644` → solo `a` (**exactamente**).
- `-perm -644` → `a`, `b`, `c`, `d`, `e`: **todos** tienen **al menos** `rw-r--r--`.
- `-perm /644` → todos: cualquiera tiene **alguno** de esos bits.
</details>

#### ⚫ Ejercicio 10.14 · Examen: ¿qué es `drwxrwsr-x`?

a) Carpeta con SUID b) Carpeta con SGID c) Carpeta con sticky d) Fichero ejecutable

<details>
<summary>💡 Ver solución</summary>

**b)** Carpeta (`d`) con **SGID** (la `s` en la `x` del **grupo**). Octal `2775`.
</details>

#### ⚫ Ejercicio 10.15 · Examen: ¿cómo busco SUID?

*¿Qué comando muestra todos los ficheros con el bit SUID del sistema?* a) `find / -perm 4000` b) `find / -perm -4000` c) `find / -type s` d) `ls -l | grep s`

<details>
<summary>💡 Ver solución</summary>

**b)** `find / -perm -4000`. (a) busca **exactamente** `4000` (ni `4755` valdría). `-type s` busca **sockets**.
</details>

#### ⚫ Ejercicio 10.16 · Examen: el sticky

*¿Qué hace el bit sticky en un directorio?* a) Impide entrar b) Hace que los ficheros hereden el grupo c) Solo el dueño del fichero (o del directorio, o root) puede borrarlo o renombrarlo d) Ejecuta con permisos de root

<details>
<summary>💡 Ver solución</summary>

**c)**. (b es el SGID; d es el SUID.)
</details>

---

⬅️ [Capítulo 9 · `chown` y `chgrp`: cambiar el dueño y el grupo](09-chown-chgrp.md) · [📚 Índice](README.md) · [Capítulo 11 · Los permisos en la vida real: el sistema, los comandos de cada día y los enlaces](11-permisos-en-la-vida-real.md) ➡️
